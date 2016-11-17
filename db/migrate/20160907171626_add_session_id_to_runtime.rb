class AddSessionIdToRuntime < ActiveRecord::Migration
  def change
    add_column :runtimes, :session_id, :string
  end
end
