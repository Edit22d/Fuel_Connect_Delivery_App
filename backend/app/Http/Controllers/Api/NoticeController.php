<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** The notification centre. Works for customers and riders. */
class NoticeController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notices = $request->user()->notices()->latest('id')->limit(50)->get()->map(fn (AppNotice $n) => [
            'id' => $n->id,
            'icon' => $n->icon,
            'title' => $n->title,
            'body' => $n->body,
            'fresh' => $n->read_at === null,
            'created_at' => $n->created_at?->toIso8601String(),
        ]);

        return response()->json(['data' => $notices, 'unread' => $notices->where('fresh', true)->count()]);
    }

    public function markRead(Request $request, AppNotice $notice): JsonResponse
    {
        abort_unless($notice->user_id === $request->user()->id, 404);
        $notice->update(['read_at' => now()]);

        return response()->json(['message' => 'Marked as read.']);
    }

    public function readAll(Request $request): JsonResponse
    {
        $request->user()->notices()->whereNull('read_at')->update(['read_at' => now()]);

        return response()->json(['message' => 'All notifications marked as read.']);
    }
}
