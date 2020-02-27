package com.lingoda.iterablesdk;

import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.google.firebase.iid.FirebaseInstanceId;
import com.iterable.iterableapi.IterableApi;
import com.iterable.iterableapi.IterableConfig;

import org.json.JSONObject;

import java.util.Locale;

public class IterableSDKModule extends ReactContextBaseJavaModule {

    private static final String KEY_PUSH_INTEGRATION_NAME = "pushIntegrationName";
    private static final String KEY_API_KEY = "apiKey";
    private static final String KEY_USER_EMAIL = "email";
    private static final String KEY_USER_ID = "id";
    private static final String KEY_DEBUG_LOGGING = "debugLogging";

    private boolean debugLogging;

    IterableSDKModule(@NonNull ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "IterableSDK";
    }

    @SuppressWarnings("unused")
    @ReactMethod
    public void init(@NonNull ReadableMap map, @NonNull Promise promise) {
        try {

            this.debugLogging = debugLogging(map);

            final String pushIntegrationName = map.getString(KEY_PUSH_INTEGRATION_NAME);
            final String apiKey = map.getString(KEY_API_KEY);

            log("#init, pushIntegrationName: %s, apiKey: %s, map: %s", pushIntegrationName, apiKey, map);

            if (TextUtils.isEmpty(apiKey)) {
                throw new IterableSDKException("'apiKey' is required for IterableSDK initialization");
            }

            final IterableConfig config = new IterableConfig.Builder()
                    .setPushIntegrationName(pushIntegrationName)
                    .setLogLevel(debugLogging ? Log.VERBOSE : Log.ERROR)
                    .build();

            IterableApi.initialize(
                    getReactApplicationContext(),
                    apiKey,
                    config);

            promise.resolve(Boolean.TRUE);

        } catch (Throwable t) {
            error(t, "#init");
            promise.reject(new IterableSDKException(t));
        }
    }

    @SuppressWarnings("unused")
    @ReactMethod
    public void login(@NonNull ReadableMap map, @NonNull Promise promise) {

        log("#login, map: %s", map);
        log("#login, deviceId: %s", FirebaseInstanceId.getInstance().getToken());

        try {

            final String userEmail = map.getString(KEY_USER_EMAIL);
            if (!TextUtils.isEmpty(userEmail)) {
                IterableApi.getInstance().setEmail(userEmail);
            } else {
                final String userId = map.getString(KEY_USER_ID);
                if (!TextUtils.isEmpty(userId)) {
                    IterableApi.getInstance().setUserId(userId);
                } else {
                    throw new IterableSDKException("Cannot set user info, pass 'email' or 'id' parameters");
                }
            }

            // update user immediately (from the docs)
            //  because it seems that setEmail and setUserId do not do it automatically
            // we also could pass some data-fields here to json-object (they also would be sent)
            IterableApi.getInstance()
                    .updateUser(new JSONObject());

            promise.resolve(Boolean.TRUE);

        } catch (Throwable t) {
            error(t, "#login");
            promise.reject(new IterableSDKException(t));
        }
    }

    @SuppressWarnings("unused")
    @ReactMethod
    public void logout(@NonNull Promise promise) {
        try {

            if (debugLogging) {
                log("#logout");
            }

            IterableApi.getInstance().disablePush();
            promise.resolve(Boolean.TRUE);
        } catch (Throwable t) {
            error(t, "#logout");
            promise.reject(new IterableSDKException(t));
        }
    }

    @SuppressWarnings("unused")
    @ReactMethod
    public void checkPermission(@NonNull Promise promise) {

        if (debugLogging) {
            log("#checkPermission");
        }

        // just resolve, so far Android doesn't have such a thing
        promise.resolve(Boolean.TRUE);
    }

    private static boolean debugLogging(@NonNull ReadableMap map) {
        return map.hasKey(KEY_DEBUG_LOGGING) && map.getBoolean(KEY_DEBUG_LOGGING);
    }

    private void log(@NonNull String message, Object... formatArgs) {
        if (debugLogging) {
            Log.i("IterableSDK", String.format(Locale.ROOT, message, formatArgs));
        }
    }

    private void error(@NonNull Throwable throwable, @NonNull String message, Object... formatArgs) {
        if (debugLogging) {
            Log.e("IterableSDK", String.format(Locale.ROOT, message, formatArgs), throwable);
        }
    }
}
