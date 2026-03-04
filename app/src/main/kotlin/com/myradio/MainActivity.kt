package com.myradio

import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionToken
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.MoreExecutors

class MainActivity : AppCompatActivity() {

    private lateinit var controllerFuture: ListenableFuture<MediaController>
    private val controller get() = if (controllerFuture.isDone) controllerFuture.get() else null

    private lateinit var adapter: StationAdapter
    private var currentStation: RadioStation? = null

    private val notifPermLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { /* ignore result, app still works without notification */ }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this, android.Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                notifPermLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS)
            }
        }

        setupRecyclerView()
        setupNowPlayingBar()
    }

    private fun setupRecyclerView() {
        adapter = StationAdapter(
            stations = RADIO_STATIONS,
            onPlayClick = { station -> playStation(station) },
            onStopClick = { stopPlayback() }
        )
        val rv = findViewById<RecyclerView>(R.id.recyclerView)
        rv.layoutManager = LinearLayoutManager(this)
        rv.addItemDecoration(DividerItemDecoration(this, DividerItemDecoration.VERTICAL))
        rv.adapter = adapter
    }

    private fun setupNowPlayingBar() {
        val nowPlayingBar = findViewById<View>(R.id.nowPlayingBar)
        nowPlayingBar.visibility = View.GONE
        findViewById<ImageButton>(R.id.btnNowPlayingStop).setOnClickListener {
            stopPlayback()
        }
    }

    override fun onStart() {
        super.onStart()
        val sessionToken = SessionToken(
            this,
            ComponentName(this, RadioService::class.java)
        )
        controllerFuture = MediaController.Builder(this, sessionToken).buildAsync()
        controllerFuture.addListener({
            val ctrl = controller ?: return@addListener
            ctrl.addListener(object : Player.Listener {
                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    updateNowPlayingBar()
                }
            })
            updateNowPlayingBar()
        }, MoreExecutors.directExecutor())
    }

    override fun onStop() {
        MediaController.releaseFuture(controllerFuture)
        super.onStop()
    }

    private fun playStation(station: RadioStation) {
        val ctrl = controller ?: run {
            Toast.makeText(this, "Connecting…", Toast.LENGTH_SHORT).show()
            return
        }
        currentStation = station
        val args = Bundle().apply { putInt(RadioService.ARG_STATION_ID, station.id) }
        ctrl.sendCustomCommand(
            SessionCommand(RadioService.COMMAND_PLAY_STATION, Bundle.EMPTY),
            args
        )
        adapter.setPlayingStation(station.id)
        updateNowPlayingBar()
    }

    private fun stopPlayback() {
        controller?.stop()
        adapter.clearPlaying()
        currentStation = null
        updateNowPlayingBar()
    }

    private fun updateNowPlayingBar() {
        val nowPlayingBar = findViewById<View>(R.id.nowPlayingBar)
        val nowPlayingText = findViewById<TextView>(R.id.nowPlayingText)
        val station = currentStation
        val isPlaying = controller?.isPlaying == true || controller?.playbackState == Player.STATE_BUFFERING

        if (station != null && isPlaying) {
            nowPlayingBar.visibility = View.VISIBLE
            nowPlayingText.text = station.name
        } else if (station != null && controller?.playbackState == Player.STATE_IDLE) {
            nowPlayingBar.visibility = View.GONE
        } else if (station != null) {
            nowPlayingBar.visibility = View.VISIBLE
            nowPlayingText.text = station.name
        } else {
            nowPlayingBar.visibility = View.GONE
        }
    }
}
