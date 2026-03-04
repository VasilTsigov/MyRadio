package com.myradio

import android.content.Context
import android.location.Geocoder
import android.location.LocationManager
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

class StationRepository(private val context: Context) {

    private fun getLastKnownLocation(): Pair<Double, Double>? {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return try {
            val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            for (provider in providers) {
                @Suppress("MissingPermission")
                val loc = lm.getLastKnownLocation(provider)
                if (loc != null) return Pair(loc.latitude, loc.longitude)
            }
            null
        } catch (e: Exception) {
            null
        }
    }

    private fun countryCodeFromLocation(lat: Double, lon: Double): String? {
        return try {
            @Suppress("DEPRECATION")
            val addresses = Geocoder(context, Locale.ENGLISH).getFromLocation(lat, lon, 1)
            addresses?.firstOrNull()?.countryCode
        } catch (e: Exception) {
            null
        }
    }

    suspend fun fetchNearbyStations(existing: List<RadioStation>): List<RadioStation> =
        withContext(Dispatchers.IO) {
            try {
                val location = getLastKnownLocation()
                Log.d(TAG, "Location: $location")

                val countryCode = if (location != null) {
                    countryCodeFromLocation(location.first, location.second)
                        ?: Locale.getDefault().country
                } else {
                    Locale.getDefault().country
                }
                Log.d(TAG, "Country code: $countryCode")

                val urlString = "https://de1.api.radio-browser.info/json/stations/search" +
                    "?countrycode=$countryCode&hidebroken=true&order=votes&reverse=true&limit=30"

                Log.d(TAG, "Fetching: $urlString")
                val json = fetchJson(urlString) ?: return@withContext emptyList<RadioStation>().also {
                    Log.w(TAG, "fetchJson returned null")
                }
                val result = parseStations(json, existing)
                Log.d(TAG, "Parsed ${result.size} stations from ${json.length()} results")
                result
            } catch (e: Exception) {
                Log.e(TAG, "fetchNearbyStations failed", e)
                emptyList()
            }
        }

    private fun fetchJson(urlString: String): JSONArray? {
        val conn = URL(urlString).openConnection() as HttpURLConnection
        return try {
            conn.setRequestProperty("User-Agent", "MyRadio/1.0")
            conn.connectTimeout = 10_000
            conn.readTimeout = 10_000
            val code = conn.responseCode
            Log.d(TAG, "HTTP $code for $urlString")
            if (code != 200) return null
            val body = conn.inputStream.bufferedReader().readText()
            JSONArray(body)
        } finally {
            conn.disconnect()
        }
    }

    companion object {
        private const val TAG = "StationRepository"
    }

    private fun parseStations(json: JSONArray, existing: List<RadioStation>): List<RadioStation> {
        val existingNames = existing.map { it.name.lowercase() }.toHashSet()
        val existingUrls = existing.map { it.streamUrl }.toHashSet()
        val result = mutableListOf<RadioStation>()
        var nextId = 1000

        for (i in 0 until json.length()) {
            val obj = json.optJSONObject(i) ?: continue
            val name = obj.optString("name").trim()
            if (name.isEmpty()) continue
            val url = obj.optString("url_resolved").trim()
            if (url.isEmpty()) continue
            val country = obj.optString("country", "")

            if (name.lowercase() in existingNames) continue
            if (url in existingUrls) continue

            existingNames.add(name.lowercase())
            existingUrls.add(url)

            result.add(
                RadioStation(
                    id = nextId++,
                    name = name,
                    streamUrl = url,
                    description = country.ifEmpty { obj.optString("tags", "") }
                )
            )
        }
        return result
    }
}
