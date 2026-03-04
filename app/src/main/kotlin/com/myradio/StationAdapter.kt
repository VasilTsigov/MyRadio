package com.myradio

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class StationAdapter(
    private val stations: List<RadioStation>,
    private val onPlayClick: (RadioStation) -> Unit,
    private val onStopClick: (RadioStation) -> Unit
) : RecyclerView.Adapter<StationAdapter.ViewHolder>() {

    private var playingId: Int = -1

    fun setPlayingStation(id: Int) {
        val old = playingId
        playingId = id
        stations.indexOfFirst { it.id == old }.takeIf { it >= 0 }?.let { notifyItemChanged(it) }
        stations.indexOfFirst { it.id == id }.takeIf { it >= 0 }?.let { notifyItemChanged(it) }
    }

    fun clearPlaying() {
        val old = playingId
        playingId = -1
        stations.indexOfFirst { it.id == old }.takeIf { it >= 0 }?.let { notifyItemChanged(it) }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_station, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val station = stations[position]
        val isPlaying = station.id == playingId
        holder.bind(station, isPlaying, onPlayClick, onStopClick)
    }

    override fun getItemCount() = stations.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val nameText: TextView = itemView.findViewById(R.id.stationName)
        private val descText: TextView = itemView.findViewById(R.id.stationDesc)
        private val playBtn: ImageButton = itemView.findViewById(R.id.btnPlay)

        fun bind(
            station: RadioStation,
            isPlaying: Boolean,
            onPlayClick: (RadioStation) -> Unit,
            onStopClick: (RadioStation) -> Unit
        ) {
            nameText.text = station.name
            descText.text = station.description
            if (isPlaying) {
                playBtn.setImageResource(R.drawable.ic_stop)
                playBtn.setOnClickListener { onStopClick(station) }
            } else {
                playBtn.setImageResource(R.drawable.ic_play)
                playBtn.setOnClickListener { onPlayClick(station) }
            }
        }
    }
}
