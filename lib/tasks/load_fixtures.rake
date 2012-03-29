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

desc "Load fixtures into the current environment's database This implementation will work for owums fixtures."

namespace :db do
   namespace :fixtures do
      task :load_custom => :environment do
         require 'active_record/fixtures'
         Dir.glob("#{Rails.root}/db/fixtures/*.yml").each do |file|
           puts "Loading db/fixtures/#{File.basename(file)}"
           Fixtures.create_fixtures('db/fixtures', File.basename(file, '.*'))
         end
      end
   end
end

# Execute db:fixtures:load_custom _before_ db:seed
Rake::Task["db:seed"].enhance ["db:fixtures:load_custom"]
