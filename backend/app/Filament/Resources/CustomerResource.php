<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CustomerResource\Pages;
use App\Filament\Resources\CustomerResource\RelationManagers\OrdersRelationManager;
use App\Models\User;
use Filament\Forms;
use Filament\Schemas\Schema;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

/** Customer management: view, edit, suspend, see their orders. */
class CustomerResource extends Resource
{
    protected static ?string $model = User::class;
    protected static ?string $slug = 'customers';
    protected static ?string $modelLabel = 'customer';
   protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-users';
  protected static string|\UnitEnum|null $navigationGroup = 'People';
    protected static ?int $navigationSort = 1;

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->where('role', User::ROLE_CUSTOMER);
    }

    public static function canCreate(): bool
    {
        return false;   // customers sign up in the app
    }

    public static function form(Schema $schema): Schema
{
    return $schema->components([
            Forms\Components\Section::make('Profile')->columns(2)->schema([
                Forms\Components\TextInput::make('name')->required()->maxLength(100),
                Forms\Components\TextInput::make('phone')->tel()->required()->unique(ignoreRecord: true),
                Forms\Components\TextInput::make('email')->email()->unique(ignoreRecord: true),
                Forms\Components\TextInput::make('emergency_contact')->tel(),
                Forms\Components\Select::make('status')->options(['active' => 'Active', 'suspended' => 'Suspended'])->required(),
                Forms\Components\TextInput::make('password')->password()->revealable()->minLength(8)
                    ->dehydrated(fn ($state) => filled($state))->helperText('Leave blank to keep the current password.'),
            ]),
            Forms\Components\Section::make('Wallet & rewards')->columns(2)->schema([
                Forms\Components\TextInput::make('wallet_balance')->numeric()->prefix('UGX')->disabled()->dehydrated(false)
                    ->helperText('Changed only through payments and refunds.'),
                Forms\Components\TextInput::make('points')->numeric()->disabled()->dehydrated(false),
            ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')->searchable()->sortable()->weight('bold'),
                Tables\Columns\TextColumn::make('phone')->searchable()->copyable(),
                Tables\Columns\TextColumn::make('email')->searchable()->toggleable(),
                Tables\Columns\TextColumn::make('orders_count')->counts('orders')->label('Orders')->sortable(),
                Tables\Columns\TextColumn::make('wallet_balance')->label('Wallet')->formatStateUsing(fn ($state) => 'UGX '.number_format($state))->sortable(),
                Tables\Columns\TextColumn::make('status')->badge()->color(fn (string $state) => $state === 'active' ? 'success' : 'danger'),
                Tables\Columns\TextColumn::make('created_at')->label('Joined')->date()->sortable(),
            ])
            ->defaultSort('id', 'desc')
            ->filters([Tables\Filters\SelectFilter::make('status')->options(['active' => 'Active', 'suspended' => 'Suspended'])])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('suspend')->icon('heroicon-o-no-symbol')->color('danger')
                    ->visible(fn (User $r) => $r->status === 'active')->requiresConfirmation()
                    ->modalDescription('The customer is signed out everywhere and can’t place orders until reactivated.')
                    ->action(function (User $r) {
                        $r->update(['status' => 'suspended']);
                        $r->tokens()->delete();
                        Notification::make()->title('Account suspended')->success()->send();
                    }),
                Tables\Actions\Action::make('activate')->icon('heroicon-o-check-circle')->color('success')
                    ->visible(fn (User $r) => $r->status === 'suspended')
                    ->action(function (User $r) {
                        $r->update(['status' => 'active']);
                        Notification::make()->title('Account reactivated')->success()->send();
                    }),
            ]);
    }

    public static function getRelations(): array
    {
        return [OrdersRelationManager::class];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCustomers::route('/'),
            'edit' => Pages\EditCustomer::route('/{record}/edit'),
        ];
    }
}
