<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;

class RevenueChart extends ChartWidget
{
    protected static ?string $heading = 'Revenue (UGX) · last 14 days';
    protected static ?int $sort = 3;
    protected int|string|array $columnSpan = 1;

    protected function getType(): string
    {
        return 'bar';
    }

    protected function getData(): array
    {
        $from = now()->subDays(13)->startOfDay();
        $rows = Order::where('delivered_at', '>=', $from)->where('status', Order::DELIVERED)
            ->selectRaw('DATE(delivered_at) as d, SUM(total) as s')->groupBy('d')->pluck('s', 'd');

        $labels = [];
        $data = [];
        for ($i = 0; $i < 14; $i++) {
            $day = $from->copy()->addDays($i);
            $labels[] = $day->format('d M');
            $data[] = (int) ($rows[$day->toDateString()] ?? 0);
        }

        return ['datasets' => [['label' => 'Revenue', 'data' => $data, 'backgroundColor' => '#F5C72E']], 'labels' => $labels];
    }
}
