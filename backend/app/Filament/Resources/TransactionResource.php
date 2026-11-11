<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TransactionResource\Pages;
use App\Models\Order;
use App\Models\Transaction;
use App\Services\OrderService;
use App\Services\PaymentService;
use App\Services\Payments\GatewayResult;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

/** Payment manager: mobile money, card, cash, wallet, refunds and rider payouts. */
class TransactionResource extends Resource
{
    protected static ?string $model = Transaction::class;
    protected static ?string $modelLabel = 'transaction';
    protected static ?string $navigationLabel = 'Payments';
    protected static ?string $navigationIcon = 'heroicon-o-banknotes';
    protected static ?string $navigationGroup = 'Money';

    public static function canCreate(): bool
    {
        return false;   // the ledger is written by the system only
    }

    public static function getNavigationBadge(): ?string
    {
        $n = Transaction::where('status', Transaction::PENDING)->whereIn('type', [Transaction::REFUND, Transaction::RIDER_PAYOUT])->count();

        return $n > 0 ? (string) $n : null;     // refunds & payouts waiting to be paid out
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }

    public static function table(Table $table): Table
    {
        $types = [
            'order_payment' => 'Order payment', 'wallet_topup' => 'Wallet top up', 'refund' => 'Refund',
            'rider_earning' => 'Rider earning', 'rider_payout' => 'Rider payout',
        ];
        $methods = ['momo' => 'MTN MoMo', 'airtel' => 'Airtel Money', 'card' => 'Card', 'wallet' => 'Wallet', 'cash' => 'Cash'];

        return $table
            ->modifyQueryUsing(fn ($q) => $q->with(['user', 'order']))
            ->columns([
                Tables\Columns\TextColumn::make('reference')->searchable()->copyable()->weight('bold'),
                Tables\Columns\TextColumn::make('user.name')->label('User')->searchable(),
                Tables\Columns\TextColumn::make('type')->badge()->formatStateUsing(fn (string $s) => $types[$s] ?? $s)->color(fn (string $s) => match ($s) {
                    'refund' => 'danger', 'rider_payout' => 'warning', 'rider_earning' => 'info', default => 'success',
                }),
                Tables\Columns\TextColumn::make('method')->badge()->formatStateUsing(fn (?string $s) => $methods[$s] ?? $s)->placeholder('—'),
                Tables\Columns\TextColumn::make('amount')->formatStateUsing(fn ($state) => 'UGX '.number_format($state))->sortable(),
                Tables\Columns\TextColumn::make('status')->badge()->color(fn (string $s) => match ($s) {
                    'successful' => 'success', 'failed' => 'danger', default => 'warning',
                }),
                Tables\Columns\TextColumn::make('order.number')->label('Order')->placeholder('—')->searchable(),
                Tables\Columns\TextColumn::make('provider_reference')->label('Provider ref')->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('created_at')->dateTime('d M, H:i')->sortable(),
            ])
            ->defaultSort('id', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('type')->options($types),
                Tables\Filters\SelectFilter::make('method')->options($methods),
                Tables\Filters\SelectFilter::make('status')->options(['pending' => 'Pending', 'successful' => 'Successful', 'failed' => 'Failed']),
                Tables\Filters\Filter::make('refunds')->label('Refund records')->query(fn ($q) => $q->where('type', Transaction::REFUND)),
            ])
            ->actions([
                Tables\Actions\Action::make('markPaid')->label('Mark as paid')->icon('heroicon-o-check-circle')->color('success')
                    ->visible(fn (Transaction $r) => $r->status === Transaction::PENDING)->requiresConfirmation()
                    ->modalDescription('Confirm the money has actually been sent / received.')
                    ->action(function (Transaction $record) {
                        if (in_array($record->type, [Transaction::ORDER_PAYMENT, Transaction::WALLET_TOPUP], true)) {
                            // Incoming money: credits the wallet / confirms the order.
                            app(PaymentService::class)->applyResult($record, new GatewayResult(GatewayResult::SUCCESSFUL, $record->provider_reference));
                            if ($record->type === Transaction::ORDER_PAYMENT && $record->order_id && ($order = Order::find($record->order_id))) {
                                app(OrderService::class)->confirm($order);
                            }
                        } else {
                            $record->update(['status' => Transaction::SUCCESSFUL]);   // refund / payout sent
                        }
                        Notification::make()->title('Marked as paid')->success()->send();
                    }),
                Tables\Actions\Action::make('markFailed')->label('Mark as failed')->icon('heroicon-o-x-circle')->color('danger')
                    ->visible(fn (Transaction $r) => $r->status === Transaction::PENDING && in_array($r->type, [Transaction::RIDER_PAYOUT, Transaction::ORDER_PAYMENT, Transaction::WALLET_TOPUP], true))
                    ->requiresConfirmation()
                    ->modalDescription('A failed rider payout returns the money to the rider’s available balance.')
                    ->action(function (Transaction $record) {
                        $record->update(['status' => Transaction::FAILED]);
                        Notification::make()->title('Marked as failed')->success()->send();
                    }),
            ]);
    }

    public static function getPages(): array
    {
        return ['index' => Pages\ManageTransactions::route('/')];
    }
}
