package fit.raize.raize_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class StepStreakWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, R.layout.step_streak_widget).apply {
                setOnClickPendingIntent(R.id.widget_title, pendingIntent)
                setTextViewText(R.id.widget_step_count, "8,420")
                setTextViewText(R.id.widget_target, "/ 10,000 steps (84%)")
                setTextViewText(R.id.widget_streak, "🔥 4d")
                setTextViewText(R.id.widget_distance, "6.2 km")
                setTextViewText(R.id.widget_calories, "345 kcal")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

