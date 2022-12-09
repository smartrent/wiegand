defmodule WiegandTest do
  use ExUnit.Case
  doctest Wiegand

  alias Wiegand.{CardData, CardFormat}

  test "encodes a standard 26-bit Wiegand card" do
    assert 0x0CA01F6 ==
             Wiegand.encode(CardFormat.hid_10301(), %CardData{card_id: 251, facility_code: 101})

    assert 0x0CA1440 ==
             Wiegand.encode(CardFormat.hid_10301(), %CardData{
               card_id: 2592,
               facility_code: 101
             })

    assert 0x1FFFFFF ==
             Wiegand.encode(CardFormat.hid_10301(), %CardData{
               card_id: 65_535,
               facility_code: 255
             })

    assert 0x0000001 == Wiegand.encode(CardFormat.hid_10301(), %CardData{card_id: 0})
  end

  test "decodes a card with no facility code or parity bits" do
    format = %CardFormat{card_id_len: 26}

    assert {:error, :bit_count} == Wiegand.decode(format, <<1::25>>)

    assert {:ok, %CardData{card_id: 1, facility_code: nil}} ==
             Wiegand.decode(format, <<1::26>>)
  end

  test "decodes a card with a facility code but no parity bits" do
    format = %CardFormat{fc_len: 10, card_id_len: 16}

    assert {:error, :bit_count} == Wiegand.decode(format, <<101::10, 999::10>>)

    assert {:ok, %CardData{card_id: 999, facility_code: 101}} ==
             Wiegand.decode(format, <<101::10, 999::16>>)
  end

  test "decodes a standard 26-bit Wiegand card" do
    assert {:error, :bit_count} == Wiegand.decode(CardFormat.hid_10301(), <<1::25>>)

    assert {:ok, %CardData{card_id: 251, facility_code: 101}} ==
             Wiegand.decode(CardFormat.hid_10301(), 0x0CA01F6)

    assert {:ok, %CardData{card_id: 251, facility_code: 101}} ==
             Wiegand.decode(
               CardFormat.hid_10301(),
               <<0b00110010100000000111110110::26>>
             )

    assert {:error, :even_parity_mismatch} ==
             Wiegand.decode(
               CardFormat.hid_10301(),
               <<0b10110010100000000111110110::26>>
             )

    assert {:error, :odd_parity_mismatch} ==
             Wiegand.decode(
               CardFormat.hid_10301(),
               <<0b00110010100000000111110111::26>>
             )
  end
end
