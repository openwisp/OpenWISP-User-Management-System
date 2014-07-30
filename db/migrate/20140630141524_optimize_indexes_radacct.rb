class OptimizeIndexesRadacct < ActiveRecord::Migration
  def self.up
    # optimize retrieval of AP specific graphs
    add_index :radacct, :CalledStationId
    
    # remove indexes that do not add much value
    remove_index :radacct, :FramedIPAddress
    remove_index :radacct, :AcctSessionId
    remove_index :radacct, :AcctUniqueId
    remove_index :radacct, :NASIPAddress
    remove_index :radacct, :CallingStationId
  end

  def self.down
    remove_index :radacct, :CalledStationId
    
    add_index :radacct, :FramedIPAddress
    add_index :radacct, :AcctSessionId
    add_index :radacct, :AcctUniqueId
    add_index :radacct, :NASIPAddress
    add_index :radacct, :CallingStationId
  end
end
