class AddNameAndPipelineToWhatsappInstances < ActiveRecord::Migration[7.1]
  def change
    add_column     :whatsapp_instances, :name, :string
    add_reference  :whatsapp_instances, :pipeline, foreign_key: true, null: true
  end
end
