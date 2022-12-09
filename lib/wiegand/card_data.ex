defmodule Wiegand.CardData do
  @moduledoc """
  Most Wiegand card formats support a facility code and a card/cardholder ID.
  """

  @type t :: %__MODULE__{
          card_id: non_neg_integer(),
          facility_code: non_neg_integer() | nil
        }

  @enforce_keys [:card_id]
  defstruct [:card_id, :facility_code]
end
