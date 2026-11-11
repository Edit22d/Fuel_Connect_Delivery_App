<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RiderResource\Pages;
use App\Models\Rider;
use App\Services\Notifier;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\HtmlString;

/** Rider management: register, approve/reject, suspend, monitor activity. */
class RiderResource extends Resource
{
    protected static ?string $model = Rider::class;
    protected static ?string $modelLabel = 'rider';
    protected static ?string $navigationIcon = 'heroicon-o-truck';
    protected static ?string $navigationGroup = 'People';
    protected static ?int $navigationSort = 2;

    public static function getNavigationBadge(): ?string
    {
        $n = Rider::where('approval_status', Rider::PENDING)->count();

        return $n > 0 ? (string) $n : null;     // pending applications
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Account')->columns(2)->schema([
                Forms\Components\TextInput::make('name')->required()->maxLength(100),
                Forms\Components\TextInput::make('phone')->tel()->required(),
                Forms\Components\TextInput::make('password')->password()->revealable()->minLength(8)
                    ->required(fn (string $operation) => $operation === 'create')
                    ->dehydrated(fn ($state) => filled($state))
                    ->helperText(fn (string $operation) => $operation === 'edit' ? 'Leave blank to keep the current password.' : null),
                Forms\Components\Select::make('user_status')->label('Account status')
                    ->options(['active' => 'Active', 'suspended' => 'Suspended'])->default('active')->required(),
            ]),
            Forms\Components\Section::make('Vehicle & licence')->columns(2)->schema([
                Forms\Components\TextInput::make('national_id')->required()->length(14),
                Forms\Components\TextInput::make('permit_number')->required(),
                Forms\Components\TextInput::make('vehicle_type')->required(),
                Forms\Components\TextInput::make('vehicle_registration')->required()->maxLength(15),
            ]),
            Forms\Components\Section::make('Approval')->columns(2)->schema([
                Forms\Components\Select::make('approval_status')
                    ->options(['pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected'])->default('approved')->required()->live(),
                Forms\Components\Toggle::make('is_online')->label('Online now'),
                Forms\Components\Textarea::make('rejection_reason')->columnSpanFull()->visible(fn (Forms\Get $get) => $get('approval_status') === 'rejected'),
                Forms\Components\Placeholder::make('documents_links')->label('Documents')->columnSpanFull()->visibleOn('edit')
                    ->content(function (?Rider $record) {
                        if (! $record || empty($record->documents)) {
                            return 'No documents uploaded.';
                        }
                        $labels = ['national_id' => 'National ID', 'permit' => 'Driving permit', 'logbook' => 'Vehicle logbook', 'photo' => 'Profile photo'];
                        $links = collect($record->documents)->map(fn ($path, $key) => '<a href="'.e(route('admin-files.rider', [$record, $key])).'" target="_blank" class="text-primary-600 underline">'.e($labels[$key] ?? $key).'</a>');

                        return new HtmlString($links->implode(' &nbsp;·&nbsp; '));
                    }),
            ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with('user'))
            ->columns([
                Tables\Columns\TextColumn::make('user.name')->label('Rider')->searchable()->weight('bold'),
                Tables\Columns\TextColumn::make('user.phone')->label('Phone')->searchable()->copyable(),
                Tables\Columns\TextColumn::make('vehicle_registration')->label('Vehicle')->description(fn (Rider $r) => $r->vehicle_type),
                Tables\Columns\TextColumn::make('approval_status')->label('Approval')->badge()->color(fn (string $s) => match ($s) {
                    'approved' => 'success', 'rejected' => 'danger', default => 'warning',
                }),
                Tables\Columns\IconColumn::make('is_online')->label('Online')->boolean(),
                Tables\Columns\TextColumn::make('deliveries')->label('Deliveries')->state(fn (Rider $r) => $r->user->deliveries()->where('status', 'delivered')->count()),
                Tables\Columns\TextColumn::make('earned')->label('Earned')->state(fn (Rider $r) => 'UGX '.number_format($r->user->transactions()->where('type', 'rider_earning')->where('status', 'successful')->sum('amount'))),
                Tables\Columns\TextColumn::make('location_updated_at')->label('Last seen')->since()->placeholder('Never'),
                Tables\Columns\TextColumn::make('user.status')->label('Account')->badge()->color(fn (?string $s) => $s === 'active' ? 'success' : 'danger'),
            ])
            ->defaultSort('id', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('approval_status')->options(['pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected']),
                Tables\Filters\TernaryFilter::make('is_online')->label('Online'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('approve')->icon('heroicon-o-check-badge')->color('success')
                    ->visible(fn (Rider $r) => $r->approval_status !== Rider::APPROVED)->requiresConfirmation()
                    ->action(function (Rider $r) {
                        $r->update(['approval_status' => Rider::APPROVED, 'approved_at' => now(), 'rejection_reason' => null]);
                        app(Notifier::class)->send($r->user, 'check', 'You’re approved!', 'Welcome to FuelConnect. Sign in to start taking deliveries.');
                        Notification::make()->title('Rider approved')->success()->send();
                    }),
                Tables\Actions\Action::make('reject')->icon('heroicon-o-x-circle')->color('danger')
                    ->visible(fn (Rider $r) => $r->approval_status === Rider::PENDING)
                    ->form([Forms\Components\Textarea::make('reason')->label('Reason (shown to the rider)')->required()])
                    ->action(function (Rider $r, array $data) {
                        $r->update(['approval_status' => Rider::REJECTED, 'rejection_reason' => $data['reason']]);
                        Notification::make()->title('Application rejected')->success()->send();
                    }),
                Tables\Actions\Action::make('suspend')->icon('heroicon-o-no-symbol')->color('danger')
                    ->visible(fn (Rider $r) => $r->user->status === 'active')->requiresConfirmation()
                    ->action(function (Rider $r) {
                        $r->user->update(['status' => 'suspended']);
                        $r->update(['is_online' => false]);
                        $r->user->tokens()->delete();
                        Notification::make()->title('Rider suspended')->success()->send();
                    }),
                Tables\Actions\Action::make('activate')->icon('heroicon-o-check-circle')->color('success')
                    ->visible(fn (Rider $r) => $r->user->status === 'suspended')
                    ->action(function (Rider $r) {
                        $r->user->update(['status' => 'active']);
                        Notification::make()->title('Rider reactivated')->success()->send();
                    }),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListRiders::route('/'),
            'create' => Pages\CreateRider::route('/create'),
            'edit' => Pages\EditRider::route('/{record}/edit'),
        ];
    }
}
