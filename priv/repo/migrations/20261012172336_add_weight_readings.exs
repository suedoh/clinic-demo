defmodule ClinicDemo.Repo.Migrations.AddWeightReadings do
  @moduledoc """
  Adds `weight_readings`, one row per weigh-in, and backfills a reading for
  every patient that already has a weight.

  Trimmed by hand from `mix ash.codegen` output: the other resources'
  snapshots predate the ash_postgres 2.14 format, so the generator also
  proposed recreating their tables. Only `weight_readings` and its snapshot
  are kept herein.

  Invariants:

    * **The backfill dates are exact.** `:record_weight` is `Patient`'s only
      update action, so a patient's `updated_at` is when its current weight
      was recorded (or when it was registered, if never re-weighed).
    * **`patients.weight_kg` is untouched.** It stays the current weight;
      the readings are its history.
    * **Readings go with their patient** (`on_delete: :delete_all`), the
      same as appointments.

  Down: drops the table. Only history is lost; every patient keeps its
  current weight.
  """

  use Ecto.Migration

  def up do
    create table(:weight_readings, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :weight_kg, :decimal, null: false

      add :recorded_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :patient_id,
          references(:patients,
            column: :id,
            name: "weight_readings_patient_id_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          ),
          null: false
    end

    # Existing patients' current weights become their first reading.
    execute("""
    INSERT INTO weight_readings (patient_id, weight_kg, recorded_at)
    SELECT id, weight_kg, updated_at
    FROM patients
    WHERE weight_kg IS NOT NULL
    """)
  end

  def down do
    drop constraint(:weight_readings, "weight_readings_patient_id_fkey")

    drop table(:weight_readings)
  end
end
