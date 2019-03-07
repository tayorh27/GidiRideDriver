package io.flutter.plugins;

import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.androidalarmmanager.AlarmService;
import io.flutter.plugins.androidalarmmanager.AndroidAlarmManagerPlugin;

public class MyApplicationFlutter extends FlutterApplication implements PluginRegistry.PluginRegistrantCallback {

    @Override
    public void onCreate() {
        super.onCreate();
        AlarmService.setPluginRegistrant(this);
    }

    @Override
    public void registerWith(PluginRegistry pluginRegistry) {
        //GeneratedPluginRegistrant.registerWith(pluginRegistry);
        //AndroidAlarmManagerPluginRegistrant.registerWith(pluginRegistry);
        //AndroidAlarmManagerPlugin.registerWith(pluginRegistry);
        AndroidAlarmManagerPlugin.registerWith(pluginRegistry.registrarFor("io.flutter.plugins.androidalarmmanager.AndroidAlarmManagerPlugin"));
    }
}
