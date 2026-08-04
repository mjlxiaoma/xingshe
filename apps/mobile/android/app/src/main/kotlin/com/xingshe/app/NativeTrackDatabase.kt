package com.xingshe.app

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Index
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase

@Entity(
    tableName = "native_track_logs",
    indices = [
        Index(value = ["tripId", "recordedAt"]),
        Index(value = ["synced"]),
    ],
)
data class NativeTrackLog(
    @PrimaryKey val nativeLogId: String,
    val tripId: String,
    val coordinateSystem: String = "WGS84",
    val latitude: Double,
    val longitude: Double,
    val altitude: Double?,
    val accuracy: Double,
    val speed: Double?,
    val bearing: Double?,
    val recordedAt: Long,
    val source: String,
    val synced: Boolean = false,
)

@Dao
interface NativeTrackLogDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    fun insert(log: NativeTrackLog): Long

    @Query(
        """
        SELECT * FROM native_track_logs
        WHERE synced = 0 AND (:tripId IS NULL OR tripId = :tripId)
        ORDER BY recordedAt, nativeLogId
        """,
    )
    fun pending(tripId: String?): List<NativeTrackLog>

    @Query("DELETE FROM native_track_logs WHERE nativeLogId IN (:ids)")
    fun delete(ids: List<String>): Int
}

@Database(entities = [NativeTrackLog::class], version = 1, exportSchema = false)
abstract class NativeTrackDatabase : RoomDatabase() {
    abstract fun logs(): NativeTrackLogDao

    companion object {
        @Volatile private var instance: NativeTrackDatabase? = null

        fun get(context: Context): NativeTrackDatabase = instance ?: synchronized(this) {
            instance ?: Room.databaseBuilder(
                context.applicationContext,
                NativeTrackDatabase::class.java,
                "native_track_logs.db",
            ).build().also { instance = it }
        }
    }
}
