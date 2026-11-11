<?php

namespace App\Filament\Resources;

use App\Filament\Resources\OrderResource\Pages;
use App\Models\Order;
use App\Models\User;
use App\Services\DeliveryService;
use App\Services\OrderService;
use Filament\Forms;
use Filament\Schemas\Schema;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\HtmlString;
use Symfony\Component\HttpKernel\Exception\HttpException;

/** All orders: view, assign riders, move through statuses, cancel. */
class OrderResource extends Resource
{
    protected static ?string $model = Order::class;
    protected static ?string $modelLabel = 'order';
    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-clipboard-document-list';
    protected static string|\UnitEnum|null $navigationGroup = 'Operations';
    protected static ?int $navigationSort = 1;

    public static function canCreate(): bool
    {
        return false;   // orders are placed by customers in the app
    }

    public static function getNavigationBadge(): ?string
    {
        $n = Order::where('status', Order::CONFIRMED)->whereNull('rider_id')->count();

        return $n > 0 ? (string) $n : null;     // waiting for a rider
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }

    private static function statusColor(string $s): string
    {
        return match ($s) {
            Order::DELIVERED => 'success',
            Order::CANCELLED => 'danger',
            Order::PENDING_PAYMENT, Order::CONFIRMED => 'warning',
            default => 'info',
        };
    }

    /** Read-only detail shown in the "View" slide-over. */
    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Order')->columns(3)->schema([
                Forms\Components\TextInput::make('number'),
                Forms\Components\TextInput::make('status')->formatStateUsing(fn ($state) => Order::STATUS_LABELS[$state] ?? $state),
                Forms\Components\TextInput::make('payment_status'),
                Forms\Components\TextInput::make('fuel_type'),
                Forms\Components\TextInput::make('litres'),
                Forms\Components\TextInput::make('payment_method'),
                Forms\Components\TextInput::make('fuel_total')->prefix('UGX'),
                Forms\Components\TextInput::make('delivery_fee')->prefix('UGX'),
                Forms\Components\TextInput::make('service_fee')->prefix('UGX'),
                Forms\Components\TextInput::make('total')->prefix('UGX'),
                Forms\Components\TextInput::make('rider_earning')->prefix('UGX'),
                Forms\Components\TextInput::make('cancellation_fee')->prefix('UGX'),
            ]),
            Forms\Components\Section::make('Delivery')->columns(2)->schema([
                Forms\Components\TextInput::make('delivery_address')->columnSpanFull(),
                Forms\Components\Textarea::make('delivery_note')->columnSpanFull(),
                Forms\Components\TextInput::make('pickup_code')->helperText('The station attendant gives this to the rider.'),
                Forms\Components\TextInput::make('delivery_code')->helperText('The customer gives this to the rider.'),
                Forms\Components\Textarea::make('cancel_reason')->columnSpanFull(),
                Forms\Components\Placeholder::make('proof')->label('Delivery photo')->columnSpanFull()
                    ->content(fn (?Order $record) => $record?->delivery_photo_path
                        ? new HtmlString('<a class="text-primary-600 underline" target="_blank" href="'.e(route('admin-files.proof', $record)).'">Open photo</a>')
                        : 'None'),
            ]),
        ])->disabled();
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($q) => $q->with(['customer', 'rider', 'station']))
            ->columns([
                Tables\Columns\TextColumn::make('number')->label('Order')->searchable()->weight('bold')->sortable(),
                Tables\Columns\TextColumn::make('customer.name')->label('Customer')->searchable(),
                Tables\Columns\TextColumn::make('station.name')->label('Station'),
                Tables\Columns\TextColumn::make('fuel_type')->label('Fuel')->formatStateUsing(fn ($state, Order $r) => "{$state} · {$r->litres}L"),
                Tables\Columns\TextColumn::make('rider.name')->label('Rider')->placeholder('Unassigned'),
                Tables\Columns\TextColumn::make('total')->formatStateUsing(fn ($state) => 'UGX '.number_format($state))->sortable(),
                Tables\Columns\TextColumn::make('payment_status')->label('Payment')->badge()->color(fn (string $s) => match ($s) {
                    'paid' => 'success', 'refunded' => 'gray', 'cod' => 'info', default => 'warning',
                })->description(fn (Order $r) => $r->payment_method),
                Tables\Columns\TextColumn::make('status')->badge()
                    ->formatStateUsing(fn (string $s) => Order::STATUS_LABELS[$s] ?? $s)->color(fn (string $s) => self::statusColor($s)),
                Tables\Columns\TextColumn::make('created_at')->label('Placed')->dateTime('d M, H:i')->sortable(),
            ])
            ->defaultSort('id', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')->options(Order::STATUS_LABELS)->multiple(),
                Tables\Filters\SelectFilter::make('payment_method')->options(['momo' => 'MTN MoMo', 'airtel' => 'Airtel Money', 'card' => 'Card', 'wallet' => 'Wallet', 'cash' => 'Cash']),
                Tables\Filters\Filter::make('unassigned')->label('Waiting for a rider')->query(fn ($q) => $q->where('status', Order::CONFIRMED)->whereNull('rider_id')),
            ])
            ->actions([
                Tables\Actions\ViewAction::make()->slideOver(),
                Tables\Actions\ActionGroup::make([
                    self::assignAction(),
                    self::statusAction(),
                    self::cancelAction(),
                ]),
            ]);
    }

    private static function assignAction(): Tables\Actions\Action
    {
        return Tables\Actions\Action::make('assign')->label('Assign rider')->icon('heroicon-o-user-plus')
            ->visible(fn (Order $r) => in_array($r->status, [Order::CONFIRMED, Order::ASSIGNED], true))
            ->form([
                Forms\Components\Select::make('rider_id')->label('Rider')->required()->searchable()
                    ->options(fn () => User::riders()->where('status', 'active')
                        ->whereHas('rider', fn ($q) => $q->where('approval_status', 'approved'))
                        ->with('rider')->get()
                        ->mapWithKeys(fn (User $u) => [$u->id => $u->name.' · '.$u->phone.($u->rider->is_online ? ' (online)' : '')])),
            ])
            ->action(function (Order $record, array $data) {
                try {
                    app(DeliveryService::class)->assign($record, User::findOrFail($data['rider_id']));
                    Notification::make()->title('Rider assigned')->success()->send();
                } catch (HttpException $e) {
                    Notification::make()->title($e->getMessage())->danger()->send();
                }
            });
    }

    /** Admin overrides go through the same services (and codes) so ledgers and notifications stay correct. */
    private static function statusAction(): Tables\Actions\Action
    {
        return Tables\Actions\Action::make('status')->label('Update status')->icon('heroicon-o-arrow-path')
            ->visible(fn (Order $r) => in_array($r->status, [Order::ASSIGNED, Order::PICKED_UP, Order::ARRIVED], true))
            ->form([
                Forms\Components\Select::make('to')->label('Move to')->required()->options([
                    Order::PICKED_UP => 'Picked up (on the way)',
                    Order::ARRIVED => 'Arrived',
                    Order::DELIVERED => 'Delivered',
                ]),
            ])
            ->action(function (Order $record, array $data) {
                $svc = app(DeliveryService::class);
                $rider = $record->rider;
                try {
                    abort_unless($rider, 422, 'Assign a rider first.');
                    match ($data['to']) {
                        Order::PICKED_UP => $svc->pickup($record, $rider, $record->pickup_code),
                        Order::ARRIVED => $svc->arrived($record, $rider),
                        Order::DELIVERED => $svc->deliver($record, $rider, $record->delivery_code),
                    };
                    Notification::make()->title('Status updated')->success()->send();
                } catch (HttpException $e) {
                    Notification::make()->title($e->getMessage())->danger()->send();
                }
            });
    }

    private static function cancelAction(): Tables\Actions\Action
    {
        return Tables\Actions\Action::make('cancel')->label('Cancel order')->icon('heroicon-o-x-circle')->color('danger')
            ->visible(fn (Order $r) => $r->isOpen())->requiresConfirmation()
            ->modalDescription('A paid order is refunded in full (no cancellation fee for admin cancellations).')
            ->form([Forms\Components\Textarea::make('reason')->required()->maxLength(255)])
            ->action(function (Order $record, array $data) {
                try {
                    app(OrderService::class)->cancel($record, $data['reason'], 'admin');
                    Notification::make()->title('Order cancelled')->success()->send();
                } catch (HttpException $e) {
                    Notification::make()->title($e->getMessage())->danger()->send();
                }
            });
    }

    public static function getPages(): array
    {
        return ['index' => Pages\ManageOrders::route('/')];
    }
}
