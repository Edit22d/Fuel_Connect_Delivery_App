<?php

namespace App\Filament\Resources\CustomerResource\RelationManagers;

use App\Models\Order;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class OrdersRelationManager extends RelationManager
{
    protected static string $relationship = 'orders';
    protected static ?string $title = 'Orders';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('number')
            ->columns([
                Tables\Columns\TextColumn::make('number')->weight('bold')->searchable(),
                Tables\Columns\TextColumn::make('station.name'),
                Tables\Columns\TextColumn::make('fuel_type')->formatStateUsing(fn ($state, Order $r) => "{$state} · {$r->litres}L"),
                Tables\Columns\TextColumn::make('total')->formatStateUsing(fn ($state) => 'UGX '.number_format($state)),
                Tables\Columns\TextColumn::make('status')->badge()
                    ->formatStateUsing(fn (string $state) => Order::STATUS_LABELS[$state] ?? $state)
                    ->color(fn (string $state) => match ($state) {
                        Order::DELIVERED => 'success', Order::CANCELLED => 'danger', default => 'warning',
                    }),
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
            ])
            ->defaultSort('id', 'desc');
    }
}
