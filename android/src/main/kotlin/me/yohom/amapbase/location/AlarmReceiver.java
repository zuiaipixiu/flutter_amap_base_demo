package me.yohom.amapbase.location;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;import me.yohom.amapbase.location.LocationService;

public class AlarmReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction().equals("TFDRIVER_LOCATION_CLOCK")) {
            Log.e("dsm_service", "--->>>   onReceive  LOCATION_CLOCK");
            Intent locationIntent = new Intent(context, LocationService.class);
            context.startService(locationIntent);
        }
    }
}
