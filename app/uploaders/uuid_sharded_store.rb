# frozen_string_literal: true

# Fan-out UUID paths so one directory never holds millions of entries.
#
#   uploads/<kind>/<aa>/<bb>/<uuid>/filename
#
# Two hex pairs → 256² = 65_536 leaf buckets. At 10M files that is ~150
# objects per directory; at 100M still low thousands (comfortable for ext4/xfs).
module UuidShardedStore
  SHARD_DEPTH = 2
  SHARD_CHARS = 2

  def store_dir
    File.join("uploads", store_kind, *uuid_shards, model.id.to_s)
  end

  private

  def store_kind
    raise NotImplementedError, "#{self.class} must define #store_kind"
  end

  def uuid_shards
    hex = model.id.to_s.delete("-").downcase
    Array.new(SHARD_DEPTH) { |index| hex[index * SHARD_CHARS, SHARD_CHARS].presence || "00" }
  end
end
