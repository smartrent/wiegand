defmodule Wiegand.CardFormat do
  @moduledoc """
  A `CardFormat` describes the bit format stored on a Wiegand card.

  ## Fields

  * `even_parity_bits` - the number of bits to sum for the even parity check
  * `odd_parity_bits` - the number of bits to sum for the odd parity check
  * `fc_len` - the size in bits of the facility code field
  * `card_id_len` the size in bits of the card ID field
  """

  @type t :: %__MODULE__{
          even_parity_bits: non_neg_integer(),
          odd_parity_bits: non_neg_integer(),
          fc_len: non_neg_integer(),
          card_id_len: non_neg_integer()
        }

  defstruct even_parity_bits: 0,
            odd_parity_bits: 0,
            fc_len: 0,
            card_id_len: 0

  @spec total_bits(t()) :: non_neg_integer()
  def total_bits(%__MODULE__{} = format) do
    even_parity_width = min(format.even_parity_bits, 1)
    odd_parity_width = min(format.odd_parity_bits, 1)
    format.card_id_len + format.fc_len + even_parity_width + odd_parity_width
  end

  @doc """
  Format for HID 10301 cards.
  """
  @spec hid_10301 :: t()
  def hid_10301(),
    do: %__MODULE__{
      even_parity_bits: 13,
      odd_parity_bits: 13,
      fc_len: 8,
      card_id_len: 16
    }

  @doc """
  Format for HID 10302 cards.
  """
  @spec hid_10302 :: t()
  def hid_10302(),
    do: %__MODULE__{
      even_parity_bits: 19,
      odd_parity_bits: 19,
      fc_len: 0,
      card_id_len: 35
    }

  @doc """
  Format for HID 10304 cards.
  """
  @spec hid_10304 :: t()
  def hid_10304(),
    do: %__MODULE__{
      even_parity_bits: 19,
      odd_parity_bits: 19,
      fc_len: 16,
      card_id_len: 19
    }
end
