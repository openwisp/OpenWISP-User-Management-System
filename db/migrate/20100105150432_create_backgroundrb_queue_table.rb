# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class CreateBackgroundrbQueueTable < ActiveRecord::Migration
  def self.up
    create_table :bdrb_job_queues do |t|
      t.column :args, :text
      t.column :worker_name, :string
      t.column :worker_method, :string
      t.column :job_key, :string
      t.column :taken, :int
      t.column :finished, :int
      t.column :timeout, :int
      t.column :priority, :int
      t.column :submitted_at, :datetime
      t.column :started_at, :datetime
      t.column :finished_at, :datetime
      t.column :archived_at, :datetime
      t.column :tag, :string
      t.column :submitter_info, :string
      t.column :runner_info, :string
      t.column :worker_key, :string
      t.column :scheduled_at, :datetime
    end
  end

  def self.down
    drop_table :bdrb_job_queues
  end
end
