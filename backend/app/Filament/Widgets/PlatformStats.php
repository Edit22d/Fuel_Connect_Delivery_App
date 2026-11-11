<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\Rider;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class PlatformStats extends StatsOverviewWidget
{
    protected static ?int $sort = 1;
    protected ?string $pollingInterval = '30s';

    protected function getStats(): array
    {
        $revenue = (int) Order::where('status', Order::DELIVERED)->sum('total');
        $monthRevenue = (int) Order::where('status', Order::DELIVERED)->where('delivered_at', '>=', now()->startOfMonth())->sum('total');
        $orders = Order::count();
        $today = Order::whereDate('created_at', today())->count();
        $onlineRiders = Rider::approved()->online()->count();
        $totalRiders = Rider::approved()->count();
        $pending = Order::whereIn('status', [Order::CONFIRMED, Order::ASSIGNED, Order::PICKED_UP, Order::ARRIVED])->count();
        $unassigned = Order::where('status', Order::CONFIRMED)->whereNull('rider_id')->count();

        return [
            Stat::make('Total revenue', 'UGX '.number_format($revenue))
                ->description('UGX '.number_format($monthRevenue).' this month')
                ->descriptionIcon('heroicon-m-banknotes')->color('success'),
            Stat::make('Total orders', number_format($orders))
                ->description("{$today} placed today")
                ->descriptionIcon('heroicon-m-shopping-bag')->color('primary'),
            Stat::make('Active riders', "{$onlineRiders} online")
                ->description("of {$totalRiders} approved")
                ->descriptionIcon('heroicon-m-truck')->color('info'),
            Stat::make('Pending deliveries', number_format($pending))
                ->description("{$unassigned} waiting for a rider")
                ->descriptionIcon('heroicon-m-clock')->color($unassigned > 0 ? 'warning' : 'success'),
        ];
    }
}
