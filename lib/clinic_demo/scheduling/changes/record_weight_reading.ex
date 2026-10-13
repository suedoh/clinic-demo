defmodule ClinicDemo.Scheduling.Changes.RecordWeightReading do
  @moduledoc """
  Appends a `WeightReading` whenever a write leaves the patient with a weight.

  Runs `after_action`, inside the same transaction as the patient write, so
  the current weight and its reading arrive together or not at all. A write
  that leaves the weight unset records nothing: registering an animal before
  it has been on the scale is common.
  """

  use Ash.Resource.Change

  alias ClinicDemo.Scheduling.WeightReading

  @impl true
  def change(changeset, _opts, context) do
    Ash.Changeset.after_action(changeset, fn _changeset, patient ->
      record_reading(patient, context)
    end)
  end

  defp record_reading(%{weight_kg: nil} = patient, _context), do: {:ok, patient}

  defp record_reading(patient, context) do
    WeightReading
    |> Ash.Changeset.for_create(
      :create,
      %{patient_id: patient.id, weight_kg: patient.weight_kg},
      actor: context.actor
    )
    |> Ash.create()
    |> case do
      {:ok, _reading} -> {:ok, patient}
      {:error, error} -> {:error, error}
    end
  end
end
