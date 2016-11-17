class AddPsapIdToRuntime < ActiveRecord::Migration
  def change
    add_column :runtimes, :psap_id, :string
  end
end
