BEGIN;

CREATE TABLE user_favorite_spots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  spot_id uuid NOT NULL REFERENCES shooting_spots(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, spot_id)
);

CREATE INDEX user_favorite_spots_user_created_idx
  ON user_favorite_spots (user_id, created_at DESC);

COMMIT;
