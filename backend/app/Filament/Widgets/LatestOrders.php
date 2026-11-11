<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

class LatestOrders extends TableWidget
{
    protected static ?string $heading = 'Latest orders';
    protected static ?int $sort = 4;
    protected int|string|array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(Order::query()->with(['customer', 'station', 'rider'])->latest('id')->limit(8))
            ->paginated(false)
            ->columns([
                Tables\Columns\TextColumn::make('number')->label('Order')->weight('bold'),
                Tables\Columns\TextColumn::make('customer.name')->label('Customer'),
                Tables\Columns\TextColumn::make('station.name')->label('Station'),
                Tables\Columns\TextColumn::make('rider.name')->label('Rider')->placeholder('Unassigned'),
                Tables\Columns\TextColumn::make('total')->formatStateUsing(fn ($state) => 'UGX '.number_format($state)),
                Tables\Columns\TextColumn::make('status')->badge()
                    ->formatStateUsing(fn (string $state) => Order::STATUS_LABELS[$state] ?? $state)
                    ->color(fn (string $state) => match ($state) {
                        Order::DELIVERED => 'success',
                        Order::CANCELLED => 'danger',
                        Order::CONFIRMED, Order::PENDING_PAYMENT => 'warning',
                        default => 'info',
                    }),
                Tables\Columns\TextColumn::make('created_at')->since(),
            ]);
    }
}
