defmodule Wiegand do
  @moduledoc """
  Encodes and decodes various formats of Wiegand card data.

  Most formats contain a facility code (though this is sometimes omitted) and a
  card/cardholder ID. Many formats provide provide error checking via parity bits.
  Even parity is calculated over the n-most-significant bits, and odd parity is
  calculated over the n-least-significant bits.

  ### Assumptions

  This package does not currently support every type of Wiegand card format.
  For simplicity's sake, it currently makes the following assumptions:

  * The even parity bit, if present, is the most-significant bit
  * The facility code, if present, immediately follows the even parity bit
  * The card/cardholder ID immediately follows the facility code
  * The odd parity bit, if present, is the least-significant bit
  * Parity checking is the only type of error checking supported
  """

  alias Wiegand.{CardData, CardFormat}
  require Integer

  @type decode_error :: :bit_count | :even_parity_mismatch | :odd_parity_mismatch

  @typep bit :: <<_::1>>
  @typep bitlist :: [0 | 1]

  @doc """
  Encodes the card data according to the given format and returns the encoded value
  as an integer.
  """
  @spec encode(CardFormat.t(), CardData.t()) :: integer()
  def encode(%CardFormat{} = format, %CardData{card_id: card_id, facility_code: facility_code}) do
    fc_data_bits = int_to_bitlist(facility_code, format.fc_len)
    card_id_data_bits = int_to_bitlist(card_id, format.card_id_len)

    card_data = fc_data_bits ++ card_id_data_bits

    [
      format |> even_parity_bit(card_data) |> List.wrap(),
      card_data,
      format |> odd_parity_bit(card_data) |> List.wrap()
    ]
    |> Enum.concat()
    |> Integer.undigits(2)
  end

  @spec decode(CardFormat.t(), bitstring() | integer()) ::
          {:ok, CardData.t()} | {:error, decode_error()}
  def decode(%CardFormat{} = format, int) when is_integer(int) do
    size = CardFormat.total_bits(format)
    bits = <<int::size(size)>>
    decode(format, bits)
  end

  def decode(
        %CardFormat{
          even_parity_bits: even_parity_bits,
          odd_parity_bits: odd_parity_bits,
          fc_len: fc_len,
          card_id_len: card_id_len
        } = format,
        bits
      ) do
    even_parity_width = min(even_parity_bits, 1)
    odd_parity_width = min(even_parity_bits, 1)
    card_data_width = fc_len + card_id_len

    if even_parity_width + odd_parity_width + card_data_width != bit_size(bits) do
      {:error, :bit_count}
    else
      <<even_parity_value::size(even_parity_width), card_data::bits-size(card_data_width),
        odd_parity_value::size(odd_parity_width)>> = bits

      <<facility_code::size(fc_len), card_id::size(card_id_len)>> = card_data

      data_bits = for <<bit::1 <- card_data>>, into: [], do: bit

      cond do
        even_parity_bits > 0 and even_parity_bit(format, data_bits) != even_parity_value ->
          {:error, :even_parity_mismatch}

        odd_parity_bits > 0 and odd_parity_bit(format, data_bits) != odd_parity_value ->
          {:error, :odd_parity_mismatch}

        true ->
          {:ok,
           %CardData{
             card_id: card_id,
             facility_code: if(fc_len == 0, do: nil, else: facility_code)
           }}
      end
    end
  end

  @spec zeropad(bitlist(), non_neg_integer()) :: bitlist()
  defp zeropad(_list, 0), do: []
  defp zeropad(list, len) when length(list) < len, do: [<<0::1>>] ++ list
  defp zeropad(list, _len), do: list

  @spec explode_bits(bitstring()) :: bitlist()
  defp explode_bits(integer), do: for(<<bit::1 <- integer>>, into: [], do: bit)

  @spec int_to_bitlist(non_neg_integer(), non_neg_integer()) :: bitlist()
  defp int_to_bitlist(nil, bit_count), do: int_to_bitlist(0, bit_count)

  defp int_to_bitlist(integer, bit_count) do
    <<integer::size(bit_count)>>
    |> explode_bits()
    |> zeropad(bit_count)
  end

  @spec even_parity_bit(CardFormat.t(), bitlist()) :: 0..1 | nil
  defp even_parity_bit(%CardFormat{even_parity_bits: 0}, _data_bits), do: nil

  defp even_parity_bit(%CardFormat{even_parity_bits: even_parity_bit_count}, data_bits) do
    data_bits
    |> Enum.take(even_parity_bit_count - 1)
    |> parity_bit(&Integer.is_even/1)
  end

  @spec odd_parity_bit(CardFormat.t(), bitlist()) :: 0..1 | nil
  defp odd_parity_bit(%CardFormat{odd_parity_bits: 0}, _data_bits), do: nil

  defp odd_parity_bit(%CardFormat{odd_parity_bits: odd_parity_bit_count}, data_bits) do
    data_bits
    |> Enum.take(-(odd_parity_bit_count - 1))
    |> parity_bit(&Integer.is_odd/1)
  end

  @spec parity_bit([bit()], (non_neg_integer() -> boolean())) :: 0..1
  defp parity_bit(bitlist, comparator) do
    bitlist
    |> Enum.sum()
    |> comparator.()
    |> case do
      true -> 0
      false -> 1
    end
  end
end
