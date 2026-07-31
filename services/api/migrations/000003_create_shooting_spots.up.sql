BEGIN;

CREATE TABLE shooting_spots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(128) NOT NULL,
  description text NOT NULL DEFAULT '',
  latitude decimal(10,7) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude decimal(10,7) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  coordinate_system varchar(16) NOT NULL DEFAULT 'GCJ02'
    CHECK (coordinate_system IN ('GCJ02', 'WGS84')),
  city_code varchar(32),
  address varchar(255),
  cover_url text,
  best_time varchar(128),
  tags jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(tags) = 'array'),
  status smallint NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX shooting_spots_status_idx ON shooting_spots (status);

INSERT INTO shooting_spots (
  id, name, description, latitude, longitude, coordinate_system,
  city_code, address, best_time, tags
) VALUES
  ('10000000-0000-4000-8000-000000000001', '外滩城市天际线', '隔江拍摄陆家嘴城市天际线。', 31.2400100, 121.4901200, 'GCJ02', '021', '上海市黄浦区中山东一路', '蓝调时刻', '["城市", "夜景", "江景"]'),
  ('10000000-0000-4000-8000-000000000002', '北山街西湖日落', '沿湖拍摄西湖水面与远山。', 30.2577900, 120.1474100, 'GCJ02', '0571', '杭州市西湖区北山街', '日落前 30 分钟', '["日落", "湖景", "人文"]'),
  ('10000000-0000-4000-8000-000000000003', '故宫角楼', '拍摄角楼与护城河倒影。', 39.9221300, 116.4039100, 'GCJ02', '010', '北京市东城区景山前街', '清晨或日落', '["建筑", "倒影", "古建"]'),
  ('10000000-0000-4000-8000-000000000004', '猎德大桥江景', '拍摄珠江新城与跨江桥梁。', 23.1158800, 113.3302800, 'GCJ02', '020', '广州市天河区临江大道', '蓝调时刻', '["城市", "桥梁", "夜景"]'),
  ('10000000-0000-4000-8000-000000000005', '深圳湾人才公园', '拍摄后海城市建筑群与水面。', 22.5166900, 113.9487600, 'GCJ02', '0755', '深圳市南山区科苑南路', '日落至蓝调时刻', '["城市", "湖景", "夜景"]'),
  ('10000000-0000-4000-8000-000000000006', '玄武湖城墙', '从湖畔拍摄城墙与城市景观。', 32.0663400, 118.7922400, 'GCJ02', '025', '南京市玄武区玄武巷', '清晨', '["城墙", "湖景", "日出"]'),
  ('10000000-0000-4000-8000-000000000007', '天府双塔', '拍摄双塔灯光与城市中轴线。', 30.5729600, 104.0651100, 'GCJ02', '028', '成都市武侯区交子大道', '亮灯后', '["城市", "建筑", "夜景"]'),
  ('10000000-0000-4000-8000-000000000008', '东湖磨山', '从湖岸拍摄山水与季节植被。', 30.5476200, 114.4147200, 'GCJ02', '027', '武汉市武昌区沿湖大道', '清晨', '["湖景", "自然", "日出"]'),
  ('10000000-0000-4000-8000-000000000009', '橘子洲头', '隔江拍摄长沙城市天际线。', 28.1978700, 112.9616500, 'GCJ02', '0731', '长沙市岳麓区橘子洲', '日落', '["城市", "江景", "日落"]'),
  ('10000000-0000-4000-8000-000000000010', '青岛栈桥', '拍摄海岸线、栈桥与回澜阁。', 36.0619100, 120.3202500, 'GCJ02', '0532', '青岛市市南区太平路', '日出前后', '["海景", "建筑", "日出"]');

COMMIT;
