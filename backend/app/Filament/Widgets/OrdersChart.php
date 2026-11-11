<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;

class OrdersChart extends ChartWidget
{
    protected static ?string $heading = 'Orders · last 14 days';
    protected static ?int $sort = 2;
    protected int|string|array $columnSpan = 1;

    protected function getType(): string
    {
        return 'line';
    }

    protected function getData(): array
    {
        $from = now()->subDays(13)->startOfDay();
        $rows = Order::where('created_at', '>=', $from)->where('status', '!=', Order::CANCELLED)
            ->selectRaw('DATE(created_at) as d, COUNT(*) as c')->groupBy('d')->pluck('c', 'd');

        $labels = [];
        $data = [];
        for ($i = 0; $i < 14; $i++) {
            $day = $from->copy()->addDays($i);
            $labels[] = $day->format('d M');
            $data[] = (int) ($rows[$day->toDateString()] ?? 0);
        }

        return ['datasets' => [['label' => 'Orders', 'data' => $data, 'borderColor' => '#F5C72E', 'backgroundColor' => 'rgba(245,199,46,.15)', 'fill' => true, 'tension' => .3]], 'labels' => $labels];
    }
}
