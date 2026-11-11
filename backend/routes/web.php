<?php

use App\Http\Controllers\AdminFileController;
use Illuminate\Support\Facades\Route;

// The only web UI is the Filament admin panel (/admin).
Route::redirect('/', '/admin');

Route::middleware('auth')->prefix('admin-files')->group(function () {
    Route::get('rider/{rider}/{doc}', [AdminFileController::class, 'riderDocument'])->name('admin-files.rider');
    Route::get('delivery-proof/{order}', [AdminFileController::class, 'deliveryProof'])->name('admin-files.proof');
});
