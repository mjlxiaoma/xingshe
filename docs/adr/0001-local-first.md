# ADR 0001: Local-first trip data

- Status: Accepted

Trip tracks, photo associations, and trip records remain on the Android device
by default. The backend stores only account, shooting-spot, and favorite data
required by the MVP.

Drift/SQLite is the source of truth for local trips and precise tracks. Logging
out or switching accounts does not delete them. Original photos are not copied
to the backend: captured photos belong to MediaStore, while imported photos
remain at their original `content://` URI. Deleting a trip removes database
associations by default; deleting a system original requires separate consent.
