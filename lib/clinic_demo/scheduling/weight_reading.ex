defmodule ClinicDemo.Scheduling.WeightReading do
  @moduledoc """
  One weigh-in: what the scale read, and when.

  Readings are clinical history, so they are append-only — there is no
  update or destroy action. A reading goes when its patient goes.
  """

  use Ash.Resource,
    domain: ClinicDemo.Scheduling,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "weight_readings"
    repo ClinicDemo.Repo

    references do
      reference :patient, on_delete: :delete
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :weight_kg, :decimal do
      description "Weight in kilograms, as read off the scale."
      allow_nil? false
      public? true
      constraints min: Decimal.new("0.01"), max: Decimal.new("120")
    end

    create_timestamp :recorded_at do
      description "When the weigh-in was recorded."
      public? true
    end
  end

  relationships do
    belongs_to :patient, ClinicDemo.Scheduling.Patient do
      description "The animal that was weighed."
      allow_nil? false
      public? true
    end
  end

  actions do
    default_accept []
    defaults [:read]

    create :create do
      description "Record one weigh-in against a patient."
      primary? true
      accept [:weight_kg, :patient_id]
    end
  end

  policies do
    policy action_type(:read) do
      description "Weight history is readable by anything that can reach the application."
      authorize_if always()
    end

    policy action_type(:create) do
      description "Only a signed-in member of staff may record a weigh-in."
      authorize_if actor_present()
    end
  end
end
