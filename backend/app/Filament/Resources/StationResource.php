<?php

namespace App\Filament\Resources;

use App\Filament\Resources\StationResource\Pages;
use App\Models\Station;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

/** Partner fuel stations and the prices customers pay. */
class StationResource extends Resource
{
    protected static ?string $model = Station::class;
    protected static ?string $modelLabel = 'station';
    protected static ?string $navigationIcon = 'heroicon-o-building-storefront';
    protected static ?string $navigationGroup = 'Network';

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Station')->columns(2)->schema([
                Forms\Components\TextInput::make('name')->required()->maxLength(120),
                Forms\Components\TextInput::make('brand')->required()->maxLength(40)->helperText('Shown in capitals: STABEX, SHELL, RUBIS…')
                    ->dehydrateStateUsing(fn ($state) => strtoupper($state)),
                Forms\Components\TextInput::make('address')->required()->columnSpanFull(),
                Forms\Components\TextInput::make('lat')->label('Latitude')->numeric()->required()->minValue(-90)->maxValue(90),
                Forms\Components\TextInput::make('lng')->label('Longitude')->numeric()->required()->minValue(-180)->maxValue(180),
                Forms\Components\TextInput::make('rating')->numeric()->minValue(1)->maxValue(5)->step(0.1)->default(4.5),
                Forms\Components\Toggle::make('is_active')->label('Visible to customers')->default(true),
                Forms\Components\FileUpload::make('image_path')->label('Photo')->image()->disk('public')->directory('stations')->columnSpanFull(),
            ]),
            Forms\Components\Section::make('Price per litre (UGX)')->description('Use 0 when a fuel isn’t sold here.')->columns(3)->schema([
                Forms\Components\TextInput::make('price_petrol')->numeric()->required()->minValue(0)->default(0),
                Forms\Components\TextInput::make('price_diesel')->numeric()->required()->minValue(0)->default(0),
                Forms\Components\TextInput::make('price_power')->numeric()->required()->minValue(0)->default(0),
            ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')->searchable()->weight('bold')->description(fn (Station $s) => $s->address),
                Tables\Columns\TextColumn::make('brand')->badge()->searchable(),
                Tables\Columns\TextColumn::make('price_petrol')->label('Petrol')->numeric()->sortable(),
                Tables\Columns\TextColumn::make('price_diesel')->label('Diesel')->numeric()->sortable(),
                Tables\Columns\TextColumn::make('price_power')->label('Power')->numeric()->sortable(),
                Tables\Columns\TextColumn::make('orders_count')->counts('orders')->label('Orders')->sortable(),
                Tables\Columns\IconColumn::make('is_active')->label('Active')->boolean(),
            ])
            ->filters([Tables\Filters\TernaryFilter::make('is_active')->label('Active')])
            ->actions([Tables\Actions\EditAction::make(), Tables\Actions\DeleteAction::make()])
            ->bulkActions([Tables\Actions\DeleteBulkAction::make()]);
    }

    public static function getPages(): array
    {
        return ['index' => Pages\ManageStations::route('/')];
    }
}
