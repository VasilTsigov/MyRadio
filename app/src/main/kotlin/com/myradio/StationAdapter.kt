package com.myradio

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class StationAdapter(
    stations: List<RadioStation>,
    private val onPlayClick: (RadioStation) -> Unit,
    private val onStopClick: () -> Unit
) : RecyclerView.Adapter<StationAdapter.ViewHolder>() {

    private val stationList: MutableList<RadioStation> = stations.toMutableList()
    private var playingId: Int = -1

    fun setPlayingStation(id: Int) {
        val old = playingId
        playingId = id
        stationList.indexOfFirst { it.id == old }.takeIf { it >= 0 }?.let { notifyItemChanged(it) }
        stationList.indexOfFirst { it.id == id }.takeIf { it >= 0 }?.let { notifyItemChanged(it) }
    }

    fun clearPlaying() {
        val old = playingId
        playingId = -1
        stationList.indexOfFirst { it.id == old }.takeIf { it >= 0 }?.let { notifyItemChanged(it) }
    }

    fun updateStations(newStations: List<RadioStation>) {
        val insertStart = stationList.size
        stationList.addAll(newStations)
        notifyItemRangeInserted(insertStart, newStations.size)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_station, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val station = stationList[position]
        val isPlaying = station.id == playingId
        holder.bind(station, isPlaying, onPlayClick, onStopClick)
    }

    override fun getItemCount() = stationList.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val nameText: TextView = itemView.findViewById(R.id.stationName)
        private val descText: TextView = itemView.findViewById(R.id.stationDesc)
        private val playBtn: ImageButton = itemView.findViewById(R.id.btnPlay)

        fun bind(
            station: RadioStation,
            isPlaying: Boolean,
            onPlayClick: (RadioStation) -> Unit,
            onStopClick: () -> Unit
        ) {
            nameText.text = station.name
            descText.text = station.description
            if (isPlaying) {
                playBtn.setImageResource(R.drawable.ic_stop)
                playBtn.setOnClickListener { onStopClick() }
                itemView.setOnClickListener { onStopClick() }
            } else {
                playBtn.setImageResource(R.drawable.ic_play)
                playBtn.setOnClickListener { onPlayClick(station) }
                itemView.setOnClickListener { onPlayClick(station) }
            }
        }
    }
}
