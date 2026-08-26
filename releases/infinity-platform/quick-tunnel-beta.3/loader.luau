--!nocheck
-- Generated WI-2026-013 universal v3 smoke; non-operational and unpublished.
-- rbx-cryptography source revision: cba3e52c78f982c128bf6573e1c04cb94937362c
-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026 daily3014; full notice in candidate THIRD_PARTY_NOTICES.txt.
local MultiPrecision, FieldQuadratic, FieldPrime, Edwards25519, Ed25519
do
--[=[
	Cryptography library: Multi-Precision Arithmetic (264-bit integers)

	Return type: varies by function
	Example usage:
		local MultiPrecision = require("MultiPrecision")

		--------Usage Case 1: Basic arithmetic--------
		local NumberA = MultiPrecision.Num(42)
		local NumberB = MultiPrecision.Num(17)
		local Sum = MultiPrecision.Add(NumberA, NumberB)
		local Product = MultiPrecision.Mul(NumberA, NumberB)

		--------Usage Case 2: Carry operations--------
		local LargeSum = MultiPrecision.Add(Sum, Product)
		local Normalized = MultiPrecision.Carry(LargeSum)
--]=]

--!strict
--!optimize 2
--!native

local CARRY = 88
local SIZE = 96

MultiPrecision = {}

function MultiPrecision.CarryWeak(LargeNumber: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10 =
		buffer.readf64(LargeNumber, 0), buffer.readf64(LargeNumber, 8),
		buffer.readf64(LargeNumber, 16), buffer.readf64(LargeNumber, 24),
		buffer.readf64(LargeNumber, 32), buffer.readf64(LargeNumber, 40),
		buffer.readf64(LargeNumber, 48), buffer.readf64(LargeNumber, 56),
		buffer.readf64(LargeNumber, 64), buffer.readf64(LargeNumber, 72),
		buffer.readf64(LargeNumber, 80)

	local Carry00 = A00 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A01 += Carry00 * 2 ^ -24
	local Carry01 = A01 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A02 += Carry01 * 2 ^ -24
	local Carry02 = A02 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A03 += Carry02 * 2 ^ -24
	local Carry03 = A03 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A04 += Carry03 * 2 ^ -24
	local Carry04 = A04 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A05 += Carry04 * 2 ^ -24
	local Carry05 = A05 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A06 += Carry05 * 2 ^ -24
	local Carry06 = A06 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A07 += Carry06 * 2 ^ -24
	local Carry07 = A07 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A08 += Carry07 * 2 ^ -24
	local Carry08 = A08 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A09 += Carry08 * 2 ^ -24
	local Carry09 = A09 + 3 * 2 ^ 75 - 3 * 2 ^ 75; A10 += Carry09 * 2 ^ -24
	local Carry10 = A10 + 3 * 2 ^ 75 - 3 * 2 ^ 75

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 - Carry00)
	buffer.writef64(Buf, 8, A01 - Carry01)
	buffer.writef64(Buf, 16, A02 - Carry02)
	buffer.writef64(Buf, 24, A03 - Carry03)
	buffer.writef64(Buf, 32, A04 - Carry04)
	buffer.writef64(Buf, 40, A05 - Carry05)
	buffer.writef64(Buf, 48, A06 - Carry06)
	buffer.writef64(Buf, 56, A07 - Carry07)
	buffer.writef64(Buf, 64, A08 - Carry08)
	buffer.writef64(Buf, 72, A09 - Carry09)
	buffer.writef64(Buf, 80, A10 - Carry10)
	buffer.writef64(Buf, 88, Carry10 * 2 ^ -24)

	return Buf
end

function MultiPrecision.Carry(LargeNumber: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10 =
		buffer.readf64(LargeNumber, 0), buffer.readf64(LargeNumber, 8),
		buffer.readf64(LargeNumber, 16), buffer.readf64(LargeNumber, 24),
		buffer.readf64(LargeNumber, 32), buffer.readf64(LargeNumber, 40),
		buffer.readf64(LargeNumber, 48), buffer.readf64(LargeNumber, 56),
		buffer.readf64(LargeNumber, 64), buffer.readf64(LargeNumber, 72),
		buffer.readf64(LargeNumber, 80)

	local Low00 = A00 % 2 ^ 24; A01 += (A00 - Low00) * 2 ^ -24
	local Low01 = A01 % 2 ^ 24; A02 += (A01 - Low01) * 2 ^ -24
	local Low02 = A02 % 2 ^ 24; A03 += (A02 - Low02) * 2 ^ -24
	local Low03 = A03 % 2 ^ 24; A04 += (A03 - Low03) * 2 ^ -24
	local Low04 = A04 % 2 ^ 24; A05 += (A04 - Low04) * 2 ^ -24
	local Low05 = A05 % 2 ^ 24; A06 += (A05 - Low05) * 2 ^ -24
	local Low06 = A06 % 2 ^ 24; A07 += (A06 - Low06) * 2 ^ -24
	local Low07 = A07 % 2 ^ 24; A08 += (A07 - Low07) * 2 ^ -24
	local Low08 = A08 % 2 ^ 24; A09 += (A08 - Low08) * 2 ^ -24
	local Low09 = A09 % 2 ^ 24; A10 += (A09 - Low09) * 2 ^ -24
	local Low10 = A10 % 2 ^ 24

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, Low00)
	buffer.writef64(Buf, 8, Low01)
	buffer.writef64(Buf, 16, Low02)
	buffer.writef64(Buf, 24, Low03)
	buffer.writef64(Buf, 32, Low04)
	buffer.writef64(Buf, 40, Low05)
	buffer.writef64(Buf, 48, Low06)
	buffer.writef64(Buf, 56, Low07)
	buffer.writef64(Buf, 64, Low08)
	buffer.writef64(Buf, 72, Low09)
	buffer.writef64(Buf, 80, Low10)
	buffer.writef64(Buf, 88, (A10 - Low10) * 2 ^ -24)

	return Buf
end

function MultiPrecision.Add(NumberA: buffer, NumberB: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10 =
		buffer.readf64(NumberA, 0), buffer.readf64(NumberA, 8),
		buffer.readf64(NumberA, 16), buffer.readf64(NumberA, 24),
		buffer.readf64(NumberA, 32), buffer.readf64(NumberA, 40),
		buffer.readf64(NumberA, 48), buffer.readf64(NumberA, 56),
		buffer.readf64(NumberA, 64), buffer.readf64(NumberA, 72),
		buffer.readf64(NumberA, 80)

	local B00, B01, B02, B03, B04, B05, B06, B07, B08, B09, B10 =
		buffer.readf64(NumberB, 0), buffer.readf64(NumberB, 8),
		buffer.readf64(NumberB, 16), buffer.readf64(NumberB, 24),
		buffer.readf64(NumberB, 32), buffer.readf64(NumberB, 40),
		buffer.readf64(NumberB, 48), buffer.readf64(NumberB, 56),
		buffer.readf64(NumberB, 64), buffer.readf64(NumberB, 72),
		buffer.readf64(NumberB, 80)

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 + B00)
	buffer.writef64(Buf, 8, A01 + B01)
	buffer.writef64(Buf, 16, A02 + B02)
	buffer.writef64(Buf, 24, A03 + B03)
	buffer.writef64(Buf, 32, A04 + B04)
	buffer.writef64(Buf, 40, A05 + B05)
	buffer.writef64(Buf, 48, A06 + B06)
	buffer.writef64(Buf, 56, A07 + B07)
	buffer.writef64(Buf, 64, A08 + B08)
	buffer.writef64(Buf, 72, A09 + B09)
	buffer.writef64(Buf, 80, A10 + B10)

	return Buf
end

function MultiPrecision.Sub(NumberA: buffer, NumberB: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10 =
		buffer.readf64(NumberA, 0), buffer.readf64(NumberA, 8),
		buffer.readf64(NumberA, 16), buffer.readf64(NumberA, 24),
		buffer.readf64(NumberA, 32), buffer.readf64(NumberA, 40),
		buffer.readf64(NumberA, 48), buffer.readf64(NumberA, 56),
		buffer.readf64(NumberA, 64), buffer.readf64(NumberA, 72),
		buffer.readf64(NumberA, 80)

	local B00, B01, B02, B03, B04, B05, B06, B07, B08, B09, B10 =
		buffer.readf64(NumberB, 0), buffer.readf64(NumberB, 8),
		buffer.readf64(NumberB, 16), buffer.readf64(NumberB, 24),
		buffer.readf64(NumberB, 32), buffer.readf64(NumberB, 40),
		buffer.readf64(NumberB, 48), buffer.readf64(NumberB, 56),
		buffer.readf64(NumberB, 64), buffer.readf64(NumberB, 72),
		buffer.readf64(NumberB, 80)

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 - B00)
	buffer.writef64(Buf, 8, A01 - B01)
	buffer.writef64(Buf, 16, A02 - B02)
	buffer.writef64(Buf, 24, A03 - B03)
	buffer.writef64(Buf, 32, A04 - B04)
	buffer.writef64(Buf, 40, A05 - B05)
	buffer.writef64(Buf, 48, A06 - B06)
	buffer.writef64(Buf, 56, A07 - B07)
	buffer.writef64(Buf, 64, A08 - B08)
	buffer.writef64(Buf, 72, A09 - B09)
	buffer.writef64(Buf, 80, A10 - B10)

	return Buf
end

function MultiPrecision.LMul(NumberA: buffer, NumberB: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10 =
		buffer.readf64(NumberA, 0), buffer.readf64(NumberA, 8),
		buffer.readf64(NumberA, 16), buffer.readf64(NumberA, 24),
		buffer.readf64(NumberA, 32), buffer.readf64(NumberA, 40),
		buffer.readf64(NumberA, 48), buffer.readf64(NumberA, 56),
		buffer.readf64(NumberA, 64), buffer.readf64(NumberA, 72),
		buffer.readf64(NumberA, 80)

	local B00, B01, B02, B03, B04, B05, B06, B07, B08, B09, B10 =
		buffer.readf64(NumberB, 0), buffer.readf64(NumberB, 8),
		buffer.readf64(NumberB, 16), buffer.readf64(NumberB, 24),
		buffer.readf64(NumberB, 32), buffer.readf64(NumberB, 40),
		buffer.readf64(NumberB, 48), buffer.readf64(NumberB, 56),
		buffer.readf64(NumberB, 64), buffer.readf64(NumberB, 72),
		buffer.readf64(NumberB, 80)

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 * B00)
	buffer.writef64(Buf, 8, A01 * B00 + A00 * B01)
	buffer.writef64(Buf, 16, A02 * B00 + A01 * B01 + A00 * B02)
	buffer.writef64(Buf, 24, A03 * B00 + A02 * B01 + A01 * B02 + A00 * B03)
	buffer.writef64(Buf, 32, A04 * B00 + A03 * B01 + A02 * B02 + A01 * B03 + A00 * B04)
	buffer.writef64(Buf, 40, A05 * B00 + A04 * B01 + A03 * B02 + A02 * B03 + A01 * B04 + A00 * B05)
	buffer.writef64(Buf, 48, A06 * B00 + A05 * B01 + A04 * B02 + A03 * B03 + A02 * B04 + A01 * B05 + A00 * B06)
	buffer.writef64(Buf, 56, A07 * B00 + A06 * B01 + A05 * B02 + A04 * B03 + A03 * B04 + A02 * B05 + A01 * B06 + A00 * B07)
	buffer.writef64(Buf, 64, A08 * B00 + A07 * B01 + A06 * B02 + A05 * B03 + A04 * B04 + A03 * B05 + A02 * B06 + A01 * B07 + A00 * B08)
	buffer.writef64(Buf, 72, A09 * B00 + A08 * B01 + A07 * B02 + A06 * B03 + A05 * B04 + A04 * B05 + A03 * B06 + A02 * B07 + A01 * B08 + A00 * B09)
	buffer.writef64(Buf, 80, A10 * B00 + A09 * B01 + A08 * B02 + A07 * B03 + A06 * B04 + A05 * B05 + A04 * B06 + A03 * B07 + A02 * B08 + A01 * B09 + A00 * B10)

	return MultiPrecision.Carry(Buf, Buf)
end

function MultiPrecision.Mul(NumberA: buffer, NumberB: buffer, LowStorage: buffer?, HighStorage: buffer?): (buffer, buffer)
	local LowResult = MultiPrecision.LMul(NumberA, NumberB, LowStorage)
	local Overflow = buffer.readf64(LowResult, CARRY)

	local A01, A02, A03, A04, A05, A06, A07, A08, A09, A10 =
		buffer.readf64(NumberA, 8), buffer.readf64(NumberA, 16),
		buffer.readf64(NumberA, 24), buffer.readf64(NumberA, 32),
		buffer.readf64(NumberA, 40), buffer.readf64(NumberA, 48),
		buffer.readf64(NumberA, 56), buffer.readf64(NumberA, 64),
		buffer.readf64(NumberA, 72), buffer.readf64(NumberA, 80)

	local B01, B02, B03, B04, B05, B06, B07, B08, B09, B10 =
		buffer.readf64(NumberB, 8), buffer.readf64(NumberB, 16),
		buffer.readf64(NumberB, 24), buffer.readf64(NumberB, 32),
		buffer.readf64(NumberB, 40), buffer.readf64(NumberB, 48),
		buffer.readf64(NumberB, 56), buffer.readf64(NumberB, 64),
		buffer.readf64(NumberB, 72), buffer.readf64(NumberB, 80)

	local Buf = HighStorage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, Overflow + A10 * B01 + A09 * B02 + A08 * B03 + A07 * B04 + A06 * B05 + A05 * B06 + A04 * B07 + A03 * B08 + A02 * B09 + A01 * B10)
	buffer.writef64(Buf, 8, A10 * B02 + A09 * B03 + A08 * B04 + A07 * B05 + A06 * B06 + A05 * B07 + A04 * B08 + A03 * B09 + A02 * B10)
	buffer.writef64(Buf, 16, A10 * B03 + A09 * B04 + A08 * B05 + A07 * B06 + A06 * B07 + A05 * B08 + A04 * B09 + A03 * B10)
	buffer.writef64(Buf, 24, A10 * B04 + A09 * B05 + A08 * B06 + A07 * B07 + A06 * B08 + A05 * B09 + A04 * B10)
	buffer.writef64(Buf, 32, A10 * B05 + A09 * B06 + A08 * B07 + A07 * B08 + A06 * B09 + A05 * B10)
	buffer.writef64(Buf, 40, A10 * B06 + A09 * B07 + A08 * B08 + A07 * B09 + A06 * B10)
	buffer.writef64(Buf, 48, A10 * B07 + A09 * B08 + A08 * B09 + A07 * B10)
	buffer.writef64(Buf, 56, A10 * B08 + A09 * B09 + A08 * B10)
	buffer.writef64(Buf, 64, A10 * B09 + A09 * B10)
	buffer.writef64(Buf, 72, A10 * B10)
	buffer.writef64(Buf, 80, 0)

	return LowResult, MultiPrecision.Carry(Buf, Buf)
end

function MultiPrecision.DWAdd(NumberA0: buffer, NumberA1: buffer, NumberB0: buffer, NumberB1: buffer, LowStorage: buffer?, HighStorage: buffer?): (buffer, buffer, number)
	local LowSum = MultiPrecision.Carry(MultiPrecision.Add(NumberA0, NumberB0, LowStorage), LowStorage)
	local CarryOut = buffer.readf64(LowSum, CARRY)

	local HighSum = MultiPrecision.Add(NumberA1, NumberB1, HighStorage)
	buffer.writef64(HighSum, 0, buffer.readf64(HighSum, 0) + CarryOut)
	local Carried = MultiPrecision.Carry(HighSum, HighSum)

	return LowSum, Carried, buffer.readf64(Carried, CARRY)
end

function MultiPrecision.Half(NumberA: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10 =
		buffer.readf64(NumberA, 0),
		buffer.readf64(NumberA, 8),
		buffer.readf64(NumberA, 16),
		buffer.readf64(NumberA, 24),
		buffer.readf64(NumberA, 32),
		buffer.readf64(NumberA, 40),
		buffer.readf64(NumberA, 48),
		buffer.readf64(NumberA, 56),
		buffer.readf64(NumberA, 64),
		buffer.readf64(NumberA, 72),
		buffer.readf64(NumberA, 80)

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 * 0.5 + A01 * 2 ^ 23)
	buffer.writef64(Buf, 8, A02 * 2 ^ 23)
	buffer.writef64(Buf, 16, A03 * 2 ^ 23)
	buffer.writef64(Buf, 24, A04 * 2 ^ 23)
	buffer.writef64(Buf, 32, A05 * 2 ^ 23)
	buffer.writef64(Buf, 40, A06 * 2 ^ 23)
	buffer.writef64(Buf, 48, A07 * 2 ^ 23)
	buffer.writef64(Buf, 56, A08 * 2 ^ 23)
	buffer.writef64(Buf, 64, A09 * 2 ^ 23)
	buffer.writef64(Buf, 72, A10 * 2 ^ 23)
	buffer.writef64(Buf, 80, 0)

	return MultiPrecision.CarryWeak(Buf, Buf)
end

function MultiPrecision.Third(NumberA: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10 =
		buffer.readf64(NumberA, 0),
		buffer.readf64(NumberA, 8),
		buffer.readf64(NumberA, 16),
		buffer.readf64(NumberA, 24),
		buffer.readf64(NumberA, 32),
		buffer.readf64(NumberA, 40),
		buffer.readf64(NumberA, 48),
		buffer.readf64(NumberA, 56),
		buffer.readf64(NumberA, 64),
		buffer.readf64(NumberA, 72),
		buffer.readf64(NumberA, 80)

	local Division00 = A00 * 0xaaaaaa
	local Division01 = A01 * 0xaaaaaa + Division00
	local Division02 = A02 * 0xaaaaaa + Division01
	local Division03 = A03 * 0xaaaaaa + Division02
	local Division04 = A04 * 0xaaaaaa + Division03
	local Division05 = A05 * 0xaaaaaa + Division04
	local Division06 = A06 * 0xaaaaaa + Division05
	local Division07 = A07 * 0xaaaaaa + Division06
	local Division08 = A08 * 0xaaaaaa + Division07
	local Division09 = A09 * 0xaaaaaa + Division08
	local Division10 = A10 * 0xaaaaaa + Division09

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 + Division00)
	buffer.writef64(Buf, 8, A01 + Division01)
	buffer.writef64(Buf, 16, A02 + Division02)
	buffer.writef64(Buf, 24, A03 + Division03)
	buffer.writef64(Buf, 32, A04 + Division04)
	buffer.writef64(Buf, 40, A05 + Division05)
	buffer.writef64(Buf, 48, A06 + Division06)
	buffer.writef64(Buf, 56, A07 + Division07)
	buffer.writef64(Buf, 64, A08 + Division08)
	buffer.writef64(Buf, 72, A09 + Division09)
	buffer.writef64(Buf, 80, A10 + Division10)

	return MultiPrecision.CarryWeak(Buf, Buf)
end

function MultiPrecision.Mod2(NumberA: buffer): number
	return buffer.readf64(NumberA, 0) % 2
end

function MultiPrecision.Mod3(NumberA: buffer): number
	return (
		buffer.readf64(NumberA, 0) +
			buffer.readf64(NumberA, 8) +
			buffer.readf64(NumberA, 16) +
			buffer.readf64(NumberA, 24) +
			buffer.readf64(NumberA, 32) +
			buffer.readf64(NumberA, 40) +
			buffer.readf64(NumberA, 48) +
			buffer.readf64(NumberA, 56) +
			buffer.readf64(NumberA, 64) +
			buffer.readf64(NumberA, 72) +
			buffer.readf64(NumberA, 80)
	) % 3
end

function MultiPrecision.Approx(NumberA: buffer): number
	return buffer.readf64(NumberA, 0)
		+ buffer.readf64(NumberA, 8) * 2 ^ 24
		+ buffer.readf64(NumberA, 16) * 2 ^ 48
		+ buffer.readf64(NumberA, 24) * 2 ^ 72
		+ buffer.readf64(NumberA, 32) * 2 ^ 96
		+ buffer.readf64(NumberA, 40) * 2 ^ 120
		+ buffer.readf64(NumberA, 48) * 2 ^ 144
		+ buffer.readf64(NumberA, 56) * 2 ^ 168
		+ buffer.readf64(NumberA, 64) * 2 ^ 192
		+ buffer.readf64(NumberA, 72) * 2 ^ 216
		+ buffer.readf64(NumberA, 80) * 2 ^ 240
end

function MultiPrecision.Cmp(NumberA: buffer, NumberB: buffer): number
	return MultiPrecision.Approx(MultiPrecision.Sub(NumberA, NumberB))
end

function MultiPrecision.Num(RegularNumber: number): buffer
	local Buf = buffer.create(SIZE)
	buffer.writef64(Buf, 0, RegularNumber)

	return Buf
end
end
do
--[=[
	Cryptography library: Field Quadratic (Curve25519 Scalar Field)

	Return type: varies by function
	Example usage:
		local FieldQuadratic = require("FieldQuadratic")

		--------Usage Case 1: Basic scalar arithmetic--------
		local ScalarA = FieldQuadratic.Decode(SomeBytes)
		local ScalarB = FieldQuadratic.Decode(OtherBytes)
		local Sum = FieldQuadratic.Add(ScalarA, ScalarB)
		local Product = FieldQuadratic.Mul(ScalarA, ScalarB)

		--------Usage Case 2: Convert to bits for scalar multiplication--------
		local ScalarBits = FieldQuadratic.Bits(ScalarA)
		local EncodedResult = FieldQuadratic.Encode(Product)
--]=]

--!strict
--!optimize 2
--!native


local CONSTANT_ZERO = MultiPrecision.Num(0)

local OUTPUT_BUFFER = buffer.create(8192)
local RULE_BUFFER = buffer.create(8192)
local DECODE_WIDE_LOW = buffer.create(96)
local DECODE_WIDE_HIGH = buffer.create(96)
local DECODE_BUFFER = buffer.create(96)
local CLAMPED_BUFFER = buffer.create(32)

local FIELD_ORDER_BYTES = buffer.create(32) do
	local Bytes = {
		0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58,
		0xd6, 0x9c, 0xf7, 0xa2, 0xde, 0xf9, 0xde, 0x14,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10
	}
	for Index = 1, 32 do
		buffer.writeu8(FIELD_ORDER_BYTES, Index - 1, Bytes[Index])
	end
end

local FIELD_ORDER = buffer.create(96) do
	local ByteIndex = 0

	for LimbIndex = 0, 9 do
		local Value = buffer.readu8(FIELD_ORDER_BYTES, ByteIndex)
			+ buffer.readu8(FIELD_ORDER_BYTES, ByteIndex + 1) * 256
			+ buffer.readu8(FIELD_ORDER_BYTES, ByteIndex + 2) * 65536

		buffer.writef64(FIELD_ORDER, LimbIndex * 8, Value)
		ByteIndex += 3
	end

	local LastValue = buffer.readu8(FIELD_ORDER_BYTES, 30)
		+ buffer.readu8(FIELD_ORDER_BYTES, 31) * 256
	buffer.writef64(FIELD_ORDER, 10 * 8, LastValue)
end

local MONTGOMERY_T0 = buffer.create(96) do
	local Values = {
		05537307, 01942290, 16765621, 16628356, 10618610,
		07072433, 03735459, 01369940, 15276086, 13038191,
		13409718
	}
	for Index = 1, 11 do
		buffer.writef64(MONTGOMERY_T0, (Index - 1) * 8, Values[Index])
	end
end

local MONTGOMERY_T1 = buffer.create(96) do
	local Values = {
		11711996, 01747860, 08326961, 03814718, 01859974,
		13327461, 16105061, 07590423, 04050668, 08138906,
		00000283
	}
	for Index = 1, 11 do
		buffer.writef64(MONTGOMERY_T1, (Index - 1) * 8, Values[Index])
	end
end

local DIVIDE_8 = buffer.create(96) do
	local Values = {
		5110253, 3039345, 2503500, 11779568, 15416472,
		16766550, 16777215, 16777215, 16777215, 16777215,
		4095
	}
	for Index = 1, 11 do
		buffer.writef64(DIVIDE_8, (Index - 1) * 8, Values[Index])
	end
end

local function Reduce(LargeNumber: buffer): buffer
	local Difference = MultiPrecision.Sub(LargeNumber, FIELD_ORDER)

	if MultiPrecision.Approx(Difference) < 0 then
		return MultiPrecision.Carry(LargeNumber)
	end

	return MultiPrecision.Carry(Difference)
end

local function Demontgomery(MontgomeryScalar: buffer): buffer
	local ReductionLow, ReductionHigh = MultiPrecision.Mul(MultiPrecision.LMul(MontgomeryScalar, MONTGOMERY_T0), FIELD_ORDER)
	local _, ResultHigh = MultiPrecision.DWAdd(MontgomeryScalar, CONSTANT_ZERO, ReductionLow, ReductionHigh)

	return Reduce(ResultHigh)
end

local function RebaseLE(InputBuffer: buffer, InputLength: number, FromBase: number, ToBase: number): (buffer, number)
	local OutputLength = 0
	local Accumulator = 0
	local Multiplier = 1

	for Index = 0, InputLength - 1 do
		Accumulator += buffer.readf64(InputBuffer, Index * 8) * Multiplier
		Multiplier *= FromBase
		while Multiplier >= ToBase do
			local Remainder = Accumulator % ToBase
			Accumulator = (Accumulator - Remainder) / ToBase
			Multiplier /= ToBase
			buffer.writef64(OUTPUT_BUFFER, OutputLength * 8, Remainder)
			OutputLength += 1
		end
	end

	if Multiplier > 0 then
		buffer.writef64(OUTPUT_BUFFER, OutputLength * 8, Accumulator)
		OutputLength += 1
	end

	return OUTPUT_BUFFER, OutputLength
end

FieldQuadratic = {}

function FieldQuadratic.IsValidScalar(ScalarBytes: buffer): boolean
	local FieldOrder = FIELD_ORDER_BYTES
	local Borrow = 0

	for Index = 0, 31 do
		local ScalarByte = buffer.readu8(ScalarBytes, Index)
		local OrderByte = buffer.readu8(FieldOrder, Index)
		local Diff = ScalarByte - OrderByte - Borrow
		Borrow = 1 - bit32.rshift(Diff + 256, 8)
	end

	return Borrow == 1
end

function FieldQuadratic.Montgomery(RegularScalar: buffer): buffer
	return FieldQuadratic.Mul(RegularScalar, MONTGOMERY_T1)
end

function FieldQuadratic.Add(ScalarA: buffer, ScalarB: buffer): buffer
	return Reduce(MultiPrecision.Add(ScalarA, ScalarB))
end

function FieldQuadratic.Neg(ScalarA: buffer): buffer
	return Reduce(MultiPrecision.Sub(FIELD_ORDER, ScalarA))
end

function FieldQuadratic.Sub(ScalarA: buffer, ScalarB: buffer): buffer
	return FieldQuadratic.Add(ScalarA, FieldQuadratic.Neg(ScalarB))
end

function FieldQuadratic.Mul(ScalarA: buffer, ScalarB: buffer): buffer
	local ProductLow, ProductHigh = MultiPrecision.Mul(ScalarA, ScalarB)
	local ReductionLow, ReductionHigh = MultiPrecision.Mul(MultiPrecision.LMul(ProductLow, MONTGOMERY_T0), FIELD_ORDER)
	local _, ResultHigh = MultiPrecision.DWAdd(ProductLow, ProductHigh, ReductionLow, ReductionHigh)

	return Reduce(ResultHigh)
end

function FieldQuadratic.Encode(MontgomeryScalar: buffer): buffer
	local DemontResult = Demontgomery(MontgomeryScalar)
	local EncodedBuffer = buffer.create(32)
	local ByteIndex = 0
	for LimbIndex = 0, 9 do
		local Value = buffer.readf64(DemontResult, LimbIndex * 8)
		buffer.writeu8(EncodedBuffer, ByteIndex, Value % 256)
		Value = Value // 256
		buffer.writeu8(EncodedBuffer, ByteIndex + 1, Value % 256)
		Value = Value // 256
		buffer.writeu8(EncodedBuffer, ByteIndex + 2, Value % 256)
		ByteIndex += 3
	end

	local LastValue = buffer.readf64(DemontResult, 10 * 8)
	buffer.writeu8(EncodedBuffer, 30, LastValue % 256)
	LastValue = LastValue // 256
	buffer.writeu8(EncodedBuffer, 31, LastValue % 256)

	return EncodedBuffer
end

function FieldQuadratic.Decode(EncodedBuffer: buffer): buffer
	local DecodedBuffer = DECODE_BUFFER
	local ByteIndex = 0

	for LimbIndex = 0, 9 do
		local Value = buffer.readu8(EncodedBuffer, ByteIndex)
			+ buffer.readu8(EncodedBuffer, ByteIndex + 1) * 256
			+ buffer.readu8(EncodedBuffer, ByteIndex + 2) * 65536

		buffer.writef64(DecodedBuffer, LimbIndex * 8, Value)
		ByteIndex += 3
	end

	local LastValue = buffer.readu8(EncodedBuffer, 30)
		+ buffer.readu8(EncodedBuffer, 31) * 256
	buffer.writef64(DecodedBuffer, 10 * 8, LastValue)

	return FieldQuadratic.Montgomery(DecodedBuffer)
end

function FieldQuadratic.DecodeWide(WideBuffer: buffer): buffer
	local LowPart = DECODE_WIDE_LOW
	local HighPart = DECODE_WIDE_HIGH

	for LimbIndex = 0, 10 do
		local ByteIndex = LimbIndex * 3
		local Value = buffer.readu8(WideBuffer, ByteIndex)
			+ buffer.readu8(WideBuffer, ByteIndex + 1) * 256
			+ buffer.readu8(WideBuffer, ByteIndex + 2) * 65536
		buffer.writef64(LowPart, LimbIndex * 8, Value)
	end

	for LimbIndex = 0, 9 do
		local ByteIndex = 33 + LimbIndex * 3
		local Value = buffer.readu8(WideBuffer, ByteIndex)
			+ buffer.readu8(WideBuffer, ByteIndex + 1) * 256
			+ buffer.readu8(WideBuffer, ByteIndex + 2) * 65536
		buffer.writef64(HighPart, LimbIndex * 8, Value)
	end
	buffer.writef64(HighPart, 10 * 8, buffer.readu8(WideBuffer, 63))

	local MontLow = FieldQuadratic.Montgomery(LowPart)
	local MontHigh = FieldQuadratic.Montgomery(HighPart)
	local MontMontHigh = FieldQuadratic.Montgomery(MontHigh)

	return FieldQuadratic.Add(MontLow, MontMontHigh)
end

function FieldQuadratic.DecodeClamped(ClampedBuffer: buffer): buffer
	local ClampedCopy = CLAMPED_BUFFER
	buffer.copy(ClampedCopy, 0, ClampedBuffer, 0, 32)

	local FirstByte = buffer.readu8(ClampedCopy, 0)
	buffer.writeu8(ClampedCopy, 0, bit32.band(FirstByte, 0xF8))

	local LastByte = buffer.readu8(ClampedCopy, 31)
	buffer.writeu8(ClampedCopy, 31, bit32.bor(bit32.band(LastByte, 0x7F), 0x40))

	return FieldQuadratic.Decode(ClampedCopy)
end

function FieldQuadratic.Eighth(MontgomeryScalar: buffer): buffer
	return FieldQuadratic.Mul(MontgomeryScalar, DIVIDE_8)
end

function FieldQuadratic.Bits(MontgomeryScalar: buffer): (buffer, number)
	local DemontResult = Demontgomery(MontgomeryScalar)
	local BitOutput, BitCount = RebaseLE(DemontResult, 11, 2 ^ 24, 2)

	if BitCount > 253 then
		BitCount = 253
	end

	return BitOutput, BitCount
end

function FieldQuadratic.MakeRuleset(ScalarA: buffer, ScalarB: buffer): (buffer, number, buffer, number)
	local DTable = Demontgomery(ScalarA)
	local ETable = Demontgomery(ScalarB)
	local FTable = MultiPrecision.Sub(DTable, ETable)

	local DMod2 = MultiPrecision.Mod2(DTable)
	local EMod2 = MultiPrecision.Mod2(ETable)

	local DMod3 = MultiPrecision.Mod3(DTable)
	local EMod3 = MultiPrecision.Mod3(ETable)

	local EFloat = MultiPrecision.Approx(ETable)
	local FFloat = MultiPrecision.Approx(FTable)

	local Mod3Lut = {[0] = 0, 2, 1}

	local RuleBuffer = RULE_BUFFER
	local RuleCount = 0

	while FFloat ~= 0 do
		local Rule = -1

		if FFloat < 0 then
			Rule = 0
			DTable, ETable = ETable, DTable
			DMod2, EMod2 = EMod2, DMod2
			DMod3, EMod3 = EMod3, DMod3
			EFloat = MultiPrecision.Approx(ETable)
			FTable = MultiPrecision.Sub(DTable, ETable)
			FFloat = -FFloat
		elseif 4 * FFloat < EFloat and DMod3 == Mod3Lut[EMod3] then
			Rule = 1
			DTable, ETable = MultiPrecision.Third(MultiPrecision.Add(DTable, FTable)), MultiPrecision.Third(MultiPrecision.Sub(ETable, FTable)) :: buffer
			DMod2, EMod2 = EMod2, DMod2
			DMod3, EMod3 = MultiPrecision.Mod3(DTable), MultiPrecision.Mod3(ETable)
			EFloat = MultiPrecision.Approx(ETable)
		elseif 4 * FFloat < EFloat and DMod2 == EMod2 and DMod3 == EMod3 then
			Rule = 2
			DTable = MultiPrecision.Half(FTable)
			DMod2 = MultiPrecision.Mod2(DTable)
			DMod3 = Mod3Lut[(DMod3 - EMod3) % 3]
			FTable = MultiPrecision.Sub(DTable, ETable)
			FFloat = MultiPrecision.Approx(FTable)
		elseif FFloat < 3 * EFloat then
			Rule = 3
			DTable = MultiPrecision.CarryWeak(FTable)
			DMod2 = (DMod2 - EMod2) % 2
			DMod3 = (DMod3 - EMod3) % 3
			FTable = MultiPrecision.Sub(DTable, ETable)
			FFloat = MultiPrecision.Approx(FTable)
		elseif DMod2 == EMod2 then
			Rule = 2
			DTable = MultiPrecision.Half(FTable)
			DMod2 = MultiPrecision.Mod2(DTable)
			DMod3 = Mod3Lut[(DMod3 - EMod3) % 3]
			FTable = MultiPrecision.Sub(DTable, ETable)
			FFloat = MultiPrecision.Approx(FTable)
		elseif DMod2 == 0 then
			Rule = 5
			DTable = MultiPrecision.Half(DTable)
			DMod2 = MultiPrecision.Mod2(DTable)
			DMod3 = Mod3Lut[DMod3]
			FTable = MultiPrecision.Sub(DTable, ETable)
			FFloat = MultiPrecision.Approx(FTable)
		elseif DMod3 == 0 then
			Rule = 6
			DTable = MultiPrecision.CarryWeak(MultiPrecision.Sub(MultiPrecision.Third(DTable), ETable))
			DMod2 = (DMod2 - EMod2) % 2
			DMod3 = MultiPrecision.Mod3(DTable)
			FTable = MultiPrecision.Sub(DTable, ETable)
			FFloat = MultiPrecision.Approx(FTable)
		elseif DMod3 == Mod3Lut[EMod3] then
			Rule = 7
			DTable = MultiPrecision.Third(MultiPrecision.Sub(FTable, ETable))
			DMod3 = MultiPrecision.Mod3(DTable)
			FTable = MultiPrecision.Sub(DTable, ETable)
			FFloat = MultiPrecision.Approx(FTable)
		elseif DMod3 == EMod3 then
			Rule = 8
			DTable = MultiPrecision.Third(FTable)
			DMod2 = (DMod2 - EMod2) % 2
			DMod3 = MultiPrecision.Mod3(DTable)
			FTable = MultiPrecision.Sub(DTable, ETable)
			FFloat = MultiPrecision.Approx(FTable)
		else
			Rule = 9
			ETable = MultiPrecision.Half(ETable)
			EMod2 = MultiPrecision.Mod2(ETable)
			EMod3 = Mod3Lut[EMod3]
			EFloat = MultiPrecision.Approx(ETable)
			FTable = MultiPrecision.Sub(DTable, ETable)
			FFloat = MultiPrecision.Approx(FTable)
		end

		buffer.writef64(RuleBuffer, RuleCount * 8, Rule)
		RuleCount += 1
	end

	local FinalBits, FinalBitCount = RebaseLE(DTable, 11, 2 ^ 24, 2)
	while FinalBitCount > 0 and buffer.readf64(FinalBits, (FinalBitCount - 1) * 8) == 0 do
		FinalBitCount -= 1
	end

	return FinalBits, FinalBitCount, RuleBuffer, RuleCount
end
end
do
--[=[
	Cryptography library: Field Prime (Curve25519 Base Field)

	Return type: varies by function
	Example usage:
		local FieldPrime = require("FieldPrime")

		--------Usage Case 1: Basic arithmetic--------
		local ElementA = FieldPrime.Num(42)
		local ElementB = FieldPrime.Num(17)
		local Sum = FieldPrime.Add(ElementA, ElementB)
		local Product = FieldPrime.Mul(ElementA, ElementB)

		--------Usage Case 2: Encoding/decoding--------
		local Encoded = FieldPrime.Encode(ElementA)
		local Decoded = FieldPrime.Decode(Encoded)
--]=]

--!strict
--!optimize 2
--!native

local SIZE = 104
local COMPOUND_V = (19 / 2 ^ 255)
local SQUARES = buffer.create(SIZE) do
	local Tbl = {
		0958640 * 2 ^ 0,
		0826664 * 2 ^ 22,
		1613251 * 2 ^ 43,
		1041528 * 2 ^ 64,
		0013673 * 2 ^ 85,
		0387171 * 2 ^ 107,
		1824679 * 2 ^ 128,
		0313839 * 2 ^ 149,
		0709440 * 2 ^ 170,
		0122635 * 2 ^ 192,
		0262782 * 2 ^ 213,
		0712905 * 2 ^ 234,
	}

	for Index = 1, 12 do
		buffer.writef64(SQUARES, (Index - 1) * 8, Tbl[Index])
	end
end

FieldPrime = {}

function FieldPrime.Num(Number: number): buffer
	local Buf = buffer.create(SIZE)
	buffer.writef64(Buf, 0, Number)

	return Buf
end

function FieldPrime.Neg(ElementA: buffer): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11 =
		buffer.readf64(ElementA, 0), buffer.readf64(ElementA, 8),
		buffer.readf64(ElementA, 16), buffer.readf64(ElementA, 24),
		buffer.readf64(ElementA, 32), buffer.readf64(ElementA, 40),
		buffer.readf64(ElementA, 48), buffer.readf64(ElementA, 56),
		buffer.readf64(ElementA, 64), buffer.readf64(ElementA, 72),
		buffer.readf64(ElementA, 80), buffer.readf64(ElementA, 88)

	local Buf = buffer.create(SIZE)

	buffer.writef64(Buf, 0, -A00)
	buffer.writef64(Buf, 8, -A01)
	buffer.writef64(Buf, 16, -A02)
	buffer.writef64(Buf, 24, -A03)
	buffer.writef64(Buf, 32, -A04)
	buffer.writef64(Buf, 40, -A05)
	buffer.writef64(Buf, 48, -A06)
	buffer.writef64(Buf, 56, -A07)
	buffer.writef64(Buf, 64, -A08)
	buffer.writef64(Buf, 72, -A09)
	buffer.writef64(Buf, 80, -A10)
	buffer.writef64(Buf, 88, -A11)

	return Buf
end

function FieldPrime.Add(ElementA: buffer, ElementB: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11 =
		buffer.readf64(ElementA, 0), buffer.readf64(ElementA, 8),
		buffer.readf64(ElementA, 16), buffer.readf64(ElementA, 24),
		buffer.readf64(ElementA, 32), buffer.readf64(ElementA, 40),
		buffer.readf64(ElementA, 48), buffer.readf64(ElementA, 56),
		buffer.readf64(ElementA, 64), buffer.readf64(ElementA, 72),
		buffer.readf64(ElementA, 80), buffer.readf64(ElementA, 88)

	local B00, B01, B02, B03, B04, B05, B06, B07, B08, B09, B10, B11 =
		buffer.readf64(ElementB, 0), buffer.readf64(ElementB, 8),
		buffer.readf64(ElementB, 16), buffer.readf64(ElementB, 24),
		buffer.readf64(ElementB, 32), buffer.readf64(ElementB, 40),
		buffer.readf64(ElementB, 48), buffer.readf64(ElementB, 56),
		buffer.readf64(ElementB, 64), buffer.readf64(ElementB, 72),
		buffer.readf64(ElementB, 80), buffer.readf64(ElementB, 88)

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 + B00)
	buffer.writef64(Buf, 8, A01 + B01)
	buffer.writef64(Buf, 16, A02 + B02)
	buffer.writef64(Buf, 24, A03 + B03)
	buffer.writef64(Buf, 32, A04 + B04)
	buffer.writef64(Buf, 40, A05 + B05)
	buffer.writef64(Buf, 48, A06 + B06)
	buffer.writef64(Buf, 56, A07 + B07)
	buffer.writef64(Buf, 64, A08 + B08)
	buffer.writef64(Buf, 72, A09 + B09)
	buffer.writef64(Buf, 80, A10 + B10)
	buffer.writef64(Buf, 88, A11 + B11)

	return Buf
end

function FieldPrime.Sub(ElementA: buffer, ElementB: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11 =
		buffer.readf64(ElementA, 0), buffer.readf64(ElementA, 8),
		buffer.readf64(ElementA, 16), buffer.readf64(ElementA, 24),
		buffer.readf64(ElementA, 32), buffer.readf64(ElementA, 40),
		buffer.readf64(ElementA, 48), buffer.readf64(ElementA, 56),
		buffer.readf64(ElementA, 64), buffer.readf64(ElementA, 72),
		buffer.readf64(ElementA, 80), buffer.readf64(ElementA, 88)

	local B00, B01, B02, B03, B04, B05, B06, B07, B08, B09, B10, B11 =
		buffer.readf64(ElementB, 0), buffer.readf64(ElementB, 8),
		buffer.readf64(ElementB, 16), buffer.readf64(ElementB, 24),
		buffer.readf64(ElementB, 32), buffer.readf64(ElementB, 40),
		buffer.readf64(ElementB, 48), buffer.readf64(ElementB, 56),
		buffer.readf64(ElementB, 64), buffer.readf64(ElementB, 72),
		buffer.readf64(ElementB, 80), buffer.readf64(ElementB, 88)

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 - B00)
	buffer.writef64(Buf, 8, A01 - B01)
	buffer.writef64(Buf, 16, A02 - B02)
	buffer.writef64(Buf, 24, A03 - B03)
	buffer.writef64(Buf, 32, A04 - B04)
	buffer.writef64(Buf, 40, A05 - B05)
	buffer.writef64(Buf, 48, A06 - B06)
	buffer.writef64(Buf, 56, A07 - B07)
	buffer.writef64(Buf, 64, A08 - B08)
	buffer.writef64(Buf, 72, A09 - B09)
	buffer.writef64(Buf, 80, A10 - B10)
	buffer.writef64(Buf, 88, A11 - B11)

	return Buf
end

function FieldPrime.Carry(ElementA: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11 =
		buffer.readf64(ElementA, 0), buffer.readf64(ElementA, 8),
		buffer.readf64(ElementA, 16), buffer.readf64(ElementA, 24),
		buffer.readf64(ElementA, 32), buffer.readf64(ElementA, 40),
		buffer.readf64(ElementA, 48), buffer.readf64(ElementA, 56),
		buffer.readf64(ElementA, 64), buffer.readf64(ElementA, 72),
		buffer.readf64(ElementA, 80), buffer.readf64(ElementA, 88)

	local C00, C01, C02, C03, C04, C05, C06, C07, C08, C09, C10, C11

	C11 = A11 + 3 * 2 ^ 306 - 3 * 2 ^ 306
	A00 += 19 / 2 ^ 255 * C11

	C00 = A00 + 3 * 2 ^ 73 - 3 * 2 ^ 73
	A01 += C00
	C01 = A01 + 3 * 2 ^ 94 - 3 * 2 ^ 94
	A02 += C01
	C02 = A02 + 3 * 2 ^ 115 - 3 * 2 ^ 115
	A03 += C02
	C03 = A03 + 3 * 2 ^ 136 - 3 * 2 ^ 136
	A04 += C03
	C04 = A04 + 3 * 2 ^ 158 - 3 * 2 ^ 158
	A05 += C04
	C05 = A05 + 3 * 2 ^ 179 - 3 * 2 ^ 179
	A06 += C05
	C06 = A06 + 3 * 2 ^ 200 - 3 * 2 ^ 200
	A07 += C06
	C07 = A07 + 3 * 2 ^ 221 - 3 * 2 ^ 221
	A08 += C07
	C08 = A08 + 3 * 2 ^ 243 - 3 * 2 ^ 243
	A09 += C08
	C09 = A09 + 3 * 2 ^ 264 - 3 * 2 ^ 264
	A10 += C09
	C10 = A10 + 3 * 2 ^ 285 - 3 * 2 ^ 285
	A11 = A11 - C11 + C10

	C11 = A11 + 3 * 2 ^ 306 - 3 * 2 ^ 306

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 - C00 + 19 / 2 ^ 255 * C11)
	buffer.writef64(Buf, 8, A01 - C01)
	buffer.writef64(Buf, 16, A02 - C02)
	buffer.writef64(Buf, 24, A03 - C03)
	buffer.writef64(Buf, 32, A04 - C04)
	buffer.writef64(Buf, 40, A05 - C05)
	buffer.writef64(Buf, 48, A06 - C06)
	buffer.writef64(Buf, 56, A07 - C07)
	buffer.writef64(Buf, 64, A08 - C08)
	buffer.writef64(Buf, 72, A09 - C09)
	buffer.writef64(Buf, 80, A10 - C10)
	buffer.writef64(Buf, 88, A11 - C11)

	return Buf
end

function FieldPrime.Canonicalize(ElementA: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11 =
		buffer.readf64(ElementA, 0), buffer.readf64(ElementA, 8),
		buffer.readf64(ElementA, 16), buffer.readf64(ElementA, 24),
		buffer.readf64(ElementA, 32), buffer.readf64(ElementA, 40),
		buffer.readf64(ElementA, 48), buffer.readf64(ElementA, 56),
		buffer.readf64(ElementA, 64), buffer.readf64(ElementA, 72),
		buffer.readf64(ElementA, 80), buffer.readf64(ElementA, 88)

	local C00, C01, C02, C03, C04, C05, C06, C07, C08, C09, C10, C11

	C00 = A00 % 2 ^ 22
	A01 += A00 - C00
	C01 = A01 % 2 ^ 43
	A02 += A01 - C01
	C02 = A02 % 2 ^ 64
	A03 += A02 - C02
	C03 = A03 % 2 ^ 85
	A04 += A03 - C03
	C04 = A04 % 2 ^ 107
	A05 += A04 - C04
	C05 = A05 % 2 ^ 128
	A06 += A05 - C05
	C06 = A06 % 2 ^ 149
	A07 += A06 - C06
	C07 = A07 % 2 ^ 170
	A08 += A07 - C07
	C08 = A08 % 2 ^ 192
	A09 += A08 - C08
	C09 = A09 % 2 ^ 213
	A10 += A09 - C09
	C10 = A10 % 2 ^ 234
	A11 += A10 - C10
	C11 = A11 % 2 ^ 255
	C00 += 19 / 2 ^ 255 * (A11 - C11)

	local Buf = Storage or buffer.create(SIZE)
	if C11 / 2 ^ 234 == 2 ^ 21 - 1
		and C10 / 2 ^ 213 == 2 ^ 21 - 1
		and C09 / 2 ^ 192 == 2 ^ 21 - 1
		and C08 / 2 ^ 170 == 2 ^ 22 - 1
		and C07 / 2 ^ 149 == 2 ^ 21 - 1
		and C06 / 2 ^ 128 == 2 ^ 21 - 1
		and C05 / 2 ^ 107 == 2 ^ 21 - 1
		and C04 / 2 ^ 85 == 2 ^ 22 - 1
		and C03 / 2 ^ 64 == 2 ^ 21 - 1
		and C02 / 2 ^ 43 == 2 ^ 21 - 1
		and C01 / 2 ^ 22 == 2 ^ 21 - 1
		and C00 >= 2 ^ 22 - 19
	then
		buffer.writef64(Buf, 0, 19 - 2 ^ 22 + C00)
		for Index = 8, 88, 8 do
			buffer.writef64(Buf, Index, 0)
		end
	else
		buffer.writef64(Buf, 0, C00)
		buffer.writef64(Buf, 8, C01)
		buffer.writef64(Buf, 16, C02)
		buffer.writef64(Buf, 24, C03)
		buffer.writef64(Buf, 32, C04)
		buffer.writef64(Buf, 40, C05)
		buffer.writef64(Buf, 48, C06)
		buffer.writef64(Buf, 56, C07)
		buffer.writef64(Buf, 64, C08)
		buffer.writef64(Buf, 72, C09)
		buffer.writef64(Buf, 80, C10)
		buffer.writef64(Buf, 88, C11)
	end

	return Buf
end

function FieldPrime.Eq(ElementA: buffer, ElementB: buffer): boolean
	local Difference = FieldPrime.Canonicalize(FieldPrime.Sub(ElementA, ElementB))
	local DifferenceAccumulator = 0
	for LimbIndex = 0, 88, 8 do
		local LimbLow = buffer.readu32(Difference, LimbIndex)
		local LimbHigh = buffer.readu32(Difference, LimbIndex + 4)
		DifferenceAccumulator = bit32.bor(DifferenceAccumulator, LimbLow, LimbHigh)
	end

	return DifferenceAccumulator == 0
end

local A00: number, A01: number, A02: number, A03: number, A04: number, A05: number, A06: number,
A07: number, A08: number, A09: number, A10: number, A11: number
local B00: number, B01: number, B02: number, B03: number, B04: number, B05: number, B06: number,
B07: number, B08: number, B09: number, B10: number, B11: number

function FieldPrime.Mul(ElementA: buffer, ElementB: buffer, Storage: buffer?): buffer
	local CompoundV = COMPOUND_V
	A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11 =
		buffer.readf64(ElementA, 0), buffer.readf64(ElementA, 8),
		buffer.readf64(ElementA, 16), buffer.readf64(ElementA, 24),
		buffer.readf64(ElementA, 32), buffer.readf64(ElementA, 40),
		buffer.readf64(ElementA, 48), buffer.readf64(ElementA, 56),
		buffer.readf64(ElementA, 64), buffer.readf64(ElementA, 72),
		buffer.readf64(ElementA, 80), buffer.readf64(ElementA, 88)

	B00, B01, B02, B03, B04, B05, B06, B07, B08, B09, B10, B11 =
		buffer.readf64(ElementB, 0), buffer.readf64(ElementB, 8),
		buffer.readf64(ElementB, 16), buffer.readf64(ElementB, 24),
		buffer.readf64(ElementB, 32), buffer.readf64(ElementB, 40),
		buffer.readf64(ElementB, 48), buffer.readf64(ElementB, 56),
		buffer.readf64(ElementB, 64), buffer.readf64(ElementB, 72),
		buffer.readf64(ElementB, 80), buffer.readf64(ElementB, 88)

	local T00: number, T01: number, T02: number, T03: number, T04: number, T05: number, T06: number,
	T07: number, T08: number, T09: number, T10: number, T11: number =
		A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11

	local U00: number, U01: number, U02: number, U03: number, U04: number, U05: number, U06: number,
	U07: number, U08: number, U09: number, U10: number, U11: number =
		B00, B01, B02, B03, B04, B05, B06, B07, B08, B09, B10, B11

	local C00 = T11 * U01
		+ T10 * U02
		+ T09 * U03
		+ T08 * U04
		+ T07 * U05
		+ T06 * U06
		+ T05 * U07
		+ T04 * U08
		+ T03 * U09
		+ T02 * U10
		+ T01 * U11

	local C01 = T11 * U02
		+ T10 * U03
		+ T09 * U04
		+ T08 * U05
		+ T07 * U06
		+ T06 * U07
		+ T05 * U08
		+ T04 * U09
		+ T03 * U10
		+ T02 * U11

	local C02 = T11 * U03
		+ T10 * U04
		+ T09 * U05
		+ T08 * U06
		+ T07 * U07
		+ T06 * U08
		+ T05 * U09
		+ T04 * U10
		+ T03 * U11

	local C03 = T11 * U04
		+ T10 * U05
		+ T09 * U06
		+ T08 * U07
		+ T07 * U08
		+ T06 * U09
		+ T05 * U10
		+ T04 * U11

	local C04 = T11 * U05
		+ T10 * U06
		+ T09 * U07
		+ T08 * U08
		+ T07 * U09
		+ T06 * U10
		+ T05 * U11

	local C05 = T11 * U06
		+ T10 * U07
		+ T09 * U08
		+ T08 * U09
		+ T07 * U10
		+ T06 * U11

	local C06 = T11 * U07
		+ T10 * U08
		+ T09 * U09
		+ T08 * U10
		+ T07 * U11

	local C07 = T11 * U08
		+ T10 * U09
		+ T09 * U10
		+ T08 * U11

	local C08 = T11 * U09
		+ T10 * U10
		+ T09 * U11

	local C09 = T11 * U10 + T10 * U11
	local C10 = T11 * U11

	C00 *= CompoundV
	C00 += T00 * U00

	C01 *= CompoundV
	C01 += T01 * U00
		+ T00 * U01

	C02 *= CompoundV
	C02 += T02 * U00
		+ T01 * U01
		+ T00 * U02

	C03 *= CompoundV
	C03 += T03 * U00
		+ T02 * U01
		+ T01 * U02
		+ T00 * U03

	C04 *= CompoundV
	C04 += T04 * U00
		+ T03 * U01
		+ T02 * U02
		+ T01 * U03
		+ T00 * U04

	C05 *= CompoundV
	C05 += T05 * U00
		+ T04 * U01
		+ T03 * U02
		+ T02 * U03
		+ T01 * U04
		+ T00 * U05

	C06 *= CompoundV
	C06 += T06 * U00
		+ T05 * U01
		+ T04 * U02
		+ T03 * U03
		+ T02 * U04
		+ T01 * U05
		+ T00 * U06

	C07 *= CompoundV
	C07 += T07 * U00
		+ T06 * U01
		+ T05 * U02
		+ T04 * U03
		+ T03 * U04
		+ T02 * U05
		+ T01 * U06
		+ T00 * U07

	C08 *= CompoundV
	C08 += T08 * U00
		+ T07 * U01
		+ T06 * U02
		+ T05 * U03
		+ T04 * U04
		+ T03 * U05
		+ T02 * U06
		+ T01 * U07
		+ T00 * U08

	C09 *= CompoundV
	C09 += T09 * U00
		+ T08 * U01
		+ T07 * U02
		+ T06 * U03
		+ T05 * U04
		+ T04 * U05
		+ T03 * U06
		+ T02 * U07
		+ T01 * U08
		+ T00 * U09

	C10 *= CompoundV
	C10 += T10 * U00
		+ T09 * U01
		+ T08 * U02
		+ T07 * U03
		+ T06 * U04
		+ T05 * U05
		+ T04 * U06
		+ T03 * U07
		+ T02 * U08
		+ T01 * U09
		+ T00 * U10

	local C11 = T11 * U00
		+ T10 * U01
		+ T09 * U02
		+ T08 * U03
		+ T07 * U04
		+ T06 * U05
		+ T05 * U06
		+ T04 * U07
		+ T03 * U08
		+ T02 * U09
		+ T01 * U10
		+ T00 * U11

	T10 = C10 + 3 * 2 ^ 285 - 3 * 2 ^ 285
	C11 += T10
	T11 = C11 + 3 * 2 ^ 306 - 3 * 2 ^ 306
	C00 += CompoundV * T11

	T00 = C00 + 3 * 2 ^ 73 - 3 * 2 ^ 73
	C01 += T00
	T01 = C01 + 3 * 2 ^ 94 - 3 * 2 ^ 94
	C02 += T01
	T02 = C02 + 3 * 2 ^ 115 - 3 * 2 ^ 115
	C03 += T02
	T03 = C03 + 3 * 2 ^ 136 - 3 * 2 ^ 136
	C04 += T03
	T04 = C04 + 3 * 2 ^ 158 - 3 * 2 ^ 158
	C05 += T04
	T05 = C05 + 3 * 2 ^ 179 - 3 * 2 ^ 179
	C06 += T05
	T06 = C06 + 3 * 2 ^ 200 - 3 * 2 ^ 200
	C07 += T06
	T07 = C07 + 3 * 2 ^ 221 - 3 * 2 ^ 221
	C08 += T07
	T08 = C08 + 3 * 2 ^ 243 - 3 * 2 ^ 243
	C09 += T08
	T09 = C09 + 3 * 2 ^ 264 - 3 * 2 ^ 264
	C10 = C10 - T10 + T09
	T10 = C10 + 3 * 2 ^ 285 - 3 * 2 ^ 285
	C11 = C11 - T11 + T10

	T11 = C11 + 3 * 2 ^ 306 - 3 * 2 ^ 306

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, C00 - T00 + CompoundV * T11)
	buffer.writef64(Buf, 8, C01 - T01)
	buffer.writef64(Buf, 16, C02 - T02)
	buffer.writef64(Buf, 24, C03 - T03)
	buffer.writef64(Buf, 32, C04 - T04)
	buffer.writef64(Buf, 40, C05 - T05)
	buffer.writef64(Buf, 48, C06 - T06)
	buffer.writef64(Buf, 56, C07 - T07)
	buffer.writef64(Buf, 64, C08 - T08)
	buffer.writef64(Buf, 72, C09 - T09)
	buffer.writef64(Buf, 80, C10 - T10)
	buffer.writef64(Buf, 88, C11 - T11)

	return Buf
end

function FieldPrime.Square(ElementA: buffer, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11 =
		buffer.readf64(ElementA, 0), buffer.readf64(ElementA, 8),
		buffer.readf64(ElementA, 16), buffer.readf64(ElementA, 24),
		buffer.readf64(ElementA, 32), buffer.readf64(ElementA, 40),
		buffer.readf64(ElementA, 48), buffer.readf64(ElementA, 56),
		buffer.readf64(ElementA, 64), buffer.readf64(ElementA, 72),
		buffer.readf64(ElementA, 80), buffer.readf64(ElementA, 88)

	local D00 = A00 * 2
	local D01 = A01 * 2
	local D02 = A02 * 2
	local D03 = A03 * 2
	local D04 = A04 * 2
	local D05 = A05 * 2
	local D06 = A06 * 2
	local D07 = A07 * 2
	local D08 = A08 * 2
	local D09 = A09 * 2
	local D10 = A10 * 2

	local ReductionFactor = 19 / 2 ^ 255

	local H00 = A11 * D01 + A10 * D02 + A09 * D03 + A08 * D04 + A07 * D05 + A06 * A06
	local H01 = A11 * D02 + A10 * D03 + A09 * D04 + A08 * D05 + A07 * D06
	local H02 = A11 * D03 + A10 * D04 + A09 * D05 + A08 * D06 + A07 * A07
	local H03 = A11 * D04 + A10 * D05 + A09 * D06 + A08 * D07
	local H04 = A11 * D05 + A10 * D06 + A09 * D07 + A08 * A08
	local H05 = A11 * D06 + A10 * D07 + A09 * D08
	local H06 = A11 * D07 + A10 * D08 + A09 * A09
	local H07 = A11 * D08 + A10 * D09
	local H08 = A11 * D09 + A10 * A10
	local H09 = A11 * D10
	local H10 = A11 * A11

	local L00 = A00 * A00
	local L01 = A01 * D00
	local L02 = A02 * D00 + A01 * A01
	local L03 = A03 * D00 + A02 * D01
	local L04 = A04 * D00 + A03 * D01 + A02 * A02
	local L05 = A05 * D00 + A04 * D01 + A03 * D02
	local L06 = A06 * D00 + A05 * D01 + A04 * D02 + A03 * A03
	local L07 = A07 * D00 + A06 * D01 + A05 * D02 + A04 * D03
	local L08 = A08 * D00 + A07 * D01 + A06 * D02 + A05 * D03 + A04 * A04
	local L09 = A09 * D00 + A08 * D01 + A07 * D02 + A06 * D03 + A05 * D04
	local L10 = A10 * D00 + A09 * D01 + A08 * D02 + A07 * D03 + A06 * D04 + A05 * A05
	local L11 = A11 * D00 + A10 * D01 + A09 * D02 + A08 * D03 + A07 * D04 + A06 * D05

	local Result = Storage or buffer.create(SIZE)
	buffer.writef64(Result, 0, H00 * ReductionFactor + L00)
	buffer.writef64(Result, 8, H01 * ReductionFactor + L01)
	buffer.writef64(Result, 16, H02 * ReductionFactor + L02)
	buffer.writef64(Result, 24, H03 * ReductionFactor + L03)
	buffer.writef64(Result, 32, H04 * ReductionFactor + L04)
	buffer.writef64(Result, 40, H05 * ReductionFactor + L05)
	buffer.writef64(Result, 48, H06 * ReductionFactor + L06)
	buffer.writef64(Result, 56, H07 * ReductionFactor + L07)
	buffer.writef64(Result, 64, H08 * ReductionFactor + L08)
	buffer.writef64(Result, 72, H09 * ReductionFactor + L09)
	buffer.writef64(Result, 80, H10 * ReductionFactor + L10)
	buffer.writef64(Result, 88, L11)

	return FieldPrime.Carry(Result, Result)
end

function FieldPrime.KMul(ElementA: buffer, SmallK: number, Storage: buffer?): buffer
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11 =
		buffer.readf64(ElementA, 0), buffer.readf64(ElementA, 8),
		buffer.readf64(ElementA, 16), buffer.readf64(ElementA, 24),
		buffer.readf64(ElementA, 32), buffer.readf64(ElementA, 40),
		buffer.readf64(ElementA, 48), buffer.readf64(ElementA, 56),
		buffer.readf64(ElementA, 64), buffer.readf64(ElementA, 72),
		buffer.readf64(ElementA, 80), buffer.readf64(ElementA, 88)

	local C00, C01, C02, C03, C04, C05, C06, C07, C08, C09, C10, C11

	A00 *= SmallK
	A01 *= SmallK
	A02 *= SmallK
	A03 *= SmallK
	A04 *= SmallK
	A05 *= SmallK
	A06 *= SmallK
	A07 *= SmallK
	A08 *= SmallK
	A09 *= SmallK
	A10 *= SmallK
	A11 *= SmallK

	C11 = A11 + 3 * 2 ^ 306 - 3 * 2 ^ 306
	A00 += 19 / 2 ^ 255 * C11

	C00 = A00 + 3 * 2 ^ 73 - 3 * 2 ^ 73
	A01 += C00
	C01 = A01 + 3 * 2 ^ 94 - 3 * 2 ^ 94
	A02 += C01
	C02 = A02 + 3 * 2 ^ 115 - 3 * 2 ^ 115
	A03 += C02
	C03 = A03 + 3 * 2 ^ 136 - 3 * 2 ^ 136
	A04 += C03
	C04 = A04 + 3 * 2 ^ 158 - 3 * 2 ^ 158
	A05 += C04
	C05 = A05 + 3 * 2 ^ 179 - 3 * 2 ^ 179
	A06 += C05
	C06 = A06 + 3 * 2 ^ 200 - 3 * 2 ^ 200
	A07 += C06
	C07 = A07 + 3 * 2 ^ 221 - 3 * 2 ^ 221
	A08 += C07
	C08 = A08 + 3 * 2 ^ 243 - 3 * 2 ^ 243
	A09 += C08
	C09 = A09 + 3 * 2 ^ 264 - 3 * 2 ^ 264
	A10 += C09
	C10 = A10 + 3 * 2 ^ 285 - 3 * 2 ^ 285
	A11 = A11 - C11 + C10

	C11 = A11 + 3 * 2 ^ 306 - 3 * 2 ^ 306

	local Buf = Storage or buffer.create(SIZE)

	buffer.writef64(Buf, 0, A00 - C00 + 19 / 2 ^ 255 * C11)
	buffer.writef64(Buf, 8, A01 - C01)
	buffer.writef64(Buf, 16, A02 - C02)
	buffer.writef64(Buf, 24, A03 - C03)
	buffer.writef64(Buf, 32, A04 - C04)
	buffer.writef64(Buf, 40, A05 - C05)
	buffer.writef64(Buf, 48, A06 - C06)
	buffer.writef64(Buf, 56, A07 - C07)
	buffer.writef64(Buf, 64, A08 - C08)
	buffer.writef64(Buf, 72, A09 - C09)
	buffer.writef64(Buf, 80, A10 - C10)
	buffer.writef64(Buf, 88, A11 - C11)

	return Buf
end

function FieldPrime.NSquare(ElementA: buffer, SquareCount: number, StoreInBuffer: boolean?): buffer
	local Square = FieldPrime.Square
	if StoreInBuffer then
		for _ = 1, SquareCount do
			Square(ElementA, ElementA)
		end

		return ElementA
	else
		for _ = 1, SquareCount do
			ElementA = Square(ElementA)
		end

		return ElementA
	end
end

function FieldPrime.Invert(ElementA: buffer, Storage: buffer?): buffer
	local Mul = FieldPrime.Mul

	local A2 = FieldPrime.Square(ElementA)
	local A9 = Mul(ElementA, FieldPrime.NSquare(A2, 2))
	local A11 = Mul(A9, A2)

	local X5 = Mul(FieldPrime.Square(A11), A9)
	local X10 = Mul(FieldPrime.NSquare(X5, 5), X5)
	local X20 = Mul(FieldPrime.NSquare(X10, 10), X10)
	local X40 = Mul(FieldPrime.NSquare(X20, 20), X20)
	local X50 = Mul(FieldPrime.NSquare(X40, 10), X10)
	local X100 = Mul(FieldPrime.NSquare(X50, 50), X50)
	local X200 = Mul(FieldPrime.NSquare(X100, 100), X100)
	local X250 = Mul(FieldPrime.NSquare(X200, 50), X50)

	return Mul(FieldPrime.NSquare(X250, 5), A11, Storage)
end

function FieldPrime.SqrtDiv(ElementU: buffer, ElementV: buffer): buffer?
	local Mul = FieldPrime.Mul
	local Square = FieldPrime.Square
	local Carry = FieldPrime.Carry

	Carry(ElementU, ElementU)

	local V2 = Square(ElementV)
	local V3 = Mul(ElementV, V2)
	local UV3 = Mul(ElementU, V3)
	local V4 = Square(V2)
	local UV7 = Mul(UV3, V4)

	local X2 = Mul(Square(UV7), UV7)
	local X4 = Mul(FieldPrime.NSquare(X2, 2), X2)
	local X8 = Mul(FieldPrime.NSquare(X4, 4), X4)
	local X16 = Mul(FieldPrime.NSquare(X8, 8), X8)
	local X18 = Mul(FieldPrime.NSquare(X16, 2), X2)
	local X32 = Mul(FieldPrime.NSquare(X16, 16), X16)
	local X50 = Mul(FieldPrime.NSquare(X32, 18), X18)
	local X100 = Mul(FieldPrime.NSquare(X50, 50), X50)
	local X200 = Mul(FieldPrime.NSquare(X100, 100), X100)
	local X250 = Mul(FieldPrime.NSquare(X200, 50), X50)
	local PowerResult = Mul(FieldPrime.NSquare(X250, 2), UV7)

	local CandidateB = Mul(UV3, PowerResult)
	local B2 = Square(CandidateB)
	local VB2 = Mul(ElementV, B2)

	if not FieldPrime.Eq(VB2, ElementU) then
		CandidateB = Mul(CandidateB, SQUARES)
		B2 = Square(CandidateB)
		VB2 = Mul(ElementV, B2)
	end

	if FieldPrime.Eq(VB2, ElementU) then
		return CandidateB
	else
		return nil
	end
end

function FieldPrime.Encode(ElementA: buffer): buffer
	ElementA = FieldPrime.Canonicalize(ElementA)
	local A00, A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11 =
		buffer.readf64(ElementA, 0), buffer.readf64(ElementA, 8),
		buffer.readf64(ElementA, 16), buffer.readf64(ElementA, 24),
		buffer.readf64(ElementA, 32), buffer.readf64(ElementA, 40),
		buffer.readf64(ElementA, 48), buffer.readf64(ElementA, 56),
		buffer.readf64(ElementA, 64), buffer.readf64(ElementA, 72),
		buffer.readf64(ElementA, 80), buffer.readf64(ElementA, 88)

	local Buf = buffer.create(32)
	local ByteIndex = 0
	local Accumulator = A00

	local Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	local Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Accumulator += A01 / 2 ^ 16

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	local Byte2 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte2)
	Accumulator = (Accumulator - Byte2) / 256
	ByteIndex += 1

	Accumulator += A02 / 2 ^ 40

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Byte2 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte2)
	Accumulator = (Accumulator - Byte2) / 256
	ByteIndex += 1

	Accumulator += A03 / 2 ^ 64

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Accumulator += A04 / 2 ^ 80

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Byte2 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte2)
	Accumulator = (Accumulator - Byte2) / 256
	ByteIndex += 1

	Accumulator += A05 / 2 ^ 104

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Byte2 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte2)
	Accumulator = (Accumulator - Byte2) / 256
	ByteIndex += 1

	Accumulator += A06 / 2 ^ 128

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Accumulator += A07 / 2 ^ 144

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Byte2 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte2)
	Accumulator = (Accumulator - Byte2) / 256
	ByteIndex += 1

	Accumulator += A08 / 2 ^ 168

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Byte2 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte2)
	Accumulator = (Accumulator - Byte2) / 256
	ByteIndex += 1

	Accumulator += A09 / 2 ^ 192

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Accumulator += A10 / 2 ^ 208

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Byte2 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte2)
	Accumulator = (Accumulator - Byte2) / 256
	ByteIndex += 1

	Accumulator += A11 / 2 ^ 232

	Byte0 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte0)
	Accumulator = (Accumulator - Byte0) / 256
	ByteIndex += 1

	Byte1 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte1)
	Accumulator = (Accumulator - Byte1) / 256
	ByteIndex += 1

	Byte2 = Accumulator % 256
	buffer.writeu8(Buf, ByteIndex, Byte2)

	return Buf
end

function FieldPrime.Decode(EncodedBytes: buffer): buffer
	local B0, B1, B2 = buffer.readu8(EncodedBytes, 0), buffer.readu8(EncodedBytes, 1), buffer.readu8(EncodedBytes, 2)
	local W00 = B0 + B1 * 256 + B2 * 65536

	B0, B1, B2 = buffer.readu8(EncodedBytes, 3), buffer.readu8(EncodedBytes, 4), buffer.readu8(EncodedBytes, 5)
	local W01 = B0 + B1 * 256 + B2 * 65536

	local W02 = buffer.readu16(EncodedBytes, 6)

	B0, B1, B2 = buffer.readu8(EncodedBytes, 8), buffer.readu8(EncodedBytes, 9), buffer.readu8(EncodedBytes, 10)
	local W03 = B0 + B1 * 256 + B2 * 65536

	B0, B1, B2 = buffer.readu8(EncodedBytes, 11), buffer.readu8(EncodedBytes, 12), buffer.readu8(EncodedBytes, 13)
	local W04 = B0 + B1 * 256 + B2 * 65536

	local W05 = buffer.readu16(EncodedBytes, 14)

	B0, B1, B2 = buffer.readu8(EncodedBytes, 16), buffer.readu8(EncodedBytes, 17), buffer.readu8(EncodedBytes, 18)
	local W06 = B0 + B1 * 256 + B2 * 65536

	B0, B1, B2 = buffer.readu8(EncodedBytes, 19), buffer.readu8(EncodedBytes, 20), buffer.readu8(EncodedBytes, 21)
	local W07 = B0 + B1 * 256 + B2 * 65536

	local W08 = buffer.readu16(EncodedBytes, 22)

	B0, B1, B2 = buffer.readu8(EncodedBytes, 24), buffer.readu8(EncodedBytes, 25), buffer.readu8(EncodedBytes, 26)
	local W09 = B0 + B1 * 256 + B2 * 65536

	B0, B1, B2 = buffer.readu8(EncodedBytes, 27), buffer.readu8(EncodedBytes, 28), buffer.readu8(EncodedBytes, 29)
	local W10 = B0 + B1 * 256 + B2 * 65536

	local W11 = buffer.readu16(EncodedBytes, 30) % 32768

	local Buf = buffer.create(SIZE)

	buffer.writef64(Buf, 0, W00)
	buffer.writef64(Buf, 8, W01 * 2 ^ 24)
	buffer.writef64(Buf, 16, W02 * 2 ^ 48)
	buffer.writef64(Buf, 24, W03 * 2 ^ 64)
	buffer.writef64(Buf, 32, W04 * 2 ^ 88)
	buffer.writef64(Buf, 40, W05 * 2 ^ 112)
	buffer.writef64(Buf, 48, W06 * 2 ^ 128)
	buffer.writef64(Buf, 56, W07 * 2 ^ 152)
	buffer.writef64(Buf, 64, W08 * 2 ^ 176)
	buffer.writef64(Buf, 72, W09 * 2 ^ 192)
	buffer.writef64(Buf, 80, W10 * 2 ^ 216)
	buffer.writef64(Buf, 88, W11 * 2 ^ 240)

	return FieldPrime.Carry(Buf, Buf)
end

function FieldPrime.Eqz(ElementA: buffer): boolean
	local Canonical = FieldPrime.Canonicalize(ElementA)
	local C00, C01, C02, C03, C04, C05, C06, C07, C08, C09, C10, C11 =
		buffer.readf64(Canonical, 0), buffer.readf64(Canonical, 8),
		buffer.readf64(Canonical, 16), buffer.readf64(Canonical, 24),
		buffer.readf64(Canonical, 32), buffer.readf64(Canonical, 40),
		buffer.readf64(Canonical, 48), buffer.readf64(Canonical, 56),
		buffer.readf64(Canonical, 64), buffer.readf64(Canonical, 72),
		buffer.readf64(Canonical, 80), buffer.readf64(Canonical, 88)

	return C00 + C01 + C02 + C03 + C04 + C05 + C06 + C07 + C08 + C09 + C10 + C11 == 0
end
end
do
--[=[
	Cryptography library: Edwards25519

	Return type: varies by function
	Example usage:
		local Edwards = require("Edwards25519")
		local FieldQuadratic = require("FieldQuadratic")

		--------Usage Case 1: Point addition--------
		local Point1 = Edwards.Decode(SomeEncodedBuffer)
		local Point2 = Edwards.Decode(AnotherEncodedBuffer)
		local NielsPoint2 = Edwards.Niels(Point2)
		local Sum = Edwards.Add(Point1, NielsPoint2)

		--------Usage Case 2: Scalar multiplication with buffer-based bits--------
		local SomeScalar = FieldQuadratic.Decode(ScalarBytes)
		local ScalarBits, BitCount = FieldQuadratic.Bits(SomeScalar)
		local Result = Edwards.MulG(ScalarBits, BitCount)
		local EncodedResult = Edwards.Encode(Result)
--]=]

--!strict
--!optimize 2
--!native


local POINT_SIZE = 416
local COORD_SIZE = 104
local AFFINE_NIELS_SIZE = 312
local BASE_RADIX_WIDTH = 6
local BASE_POINT_ROW = 2 ^ BASE_RADIX_WIDTH / 2

local CURVE_D = FieldPrime.Mul(FieldPrime.Num(-121665), FieldPrime.Invert(FieldPrime.Num(121666)))
local CURVE_K = FieldPrime.KMul(CURVE_D, 2)

local IDENTITY_O = buffer.create(POINT_SIZE) do
	buffer.copy(IDENTITY_O, 0, FieldPrime.Num(0), 0, COORD_SIZE)
	buffer.copy(IDENTITY_O, COORD_SIZE, FieldPrime.Num(1), 0, COORD_SIZE)
	buffer.copy(IDENTITY_O, 2 * COORD_SIZE, FieldPrime.Num(1), 0, COORD_SIZE)
	buffer.copy(IDENTITY_O, 3 * COORD_SIZE, FieldPrime.Num(0), 0, COORD_SIZE)
end

local COORD_BUFFER_0 = buffer.create(COORD_SIZE)
local COORD_BUFFER_1 = buffer.create(COORD_SIZE)
local COORD_BUFFER_2 = buffer.create(COORD_SIZE)
local COORD_BUFFER_3 = buffer.create(COORD_SIZE)
local COORD_BUFFER_4 = buffer.create(COORD_SIZE)
local COORD_BUFFER_5 = buffer.create(COORD_SIZE)
local COORD_BUFFER_6 = buffer.create(COORD_SIZE)
local COORD_BUFFER_7 = buffer.create(COORD_SIZE)

local MUL_RESULT_POINT = buffer.create(POINT_SIZE)
local MUL_NIELS_POINT = buffer.create(POINT_SIZE)
local MUL_DOUBLE_X = buffer.create(COORD_SIZE)
local MUL_DOUBLE_Y = buffer.create(COORD_SIZE)
local MUL_DOUBLE_Z = buffer.create(COORD_SIZE)
local MUL_DOUBLE_A = buffer.create(COORD_SIZE)
local MUL_DOUBLE_B = buffer.create(COORD_SIZE)
local MUL_DOUBLE_E = buffer.create(COORD_SIZE)
local MUL_DOUBLE_G = buffer.create(COORD_SIZE)
local MUL_P1X = buffer.create(COORD_SIZE)
local MUL_P1Y = buffer.create(COORD_SIZE)
local MUL_P1Z = buffer.create(COORD_SIZE)
local MUL_P1T = buffer.create(COORD_SIZE)
local MUL_N2P = buffer.create(COORD_SIZE)
local MUL_N2M = buffer.create(COORD_SIZE)
local MUL_N2Z = buffer.create(COORD_SIZE)
local MUL_N2T = buffer.create(COORD_SIZE)
local MUL_TMP = buffer.create(COORD_SIZE)

local MULG_RESULT_POINT = buffer.create(POINT_SIZE)
local MULG_AFFINE_NIELS = buffer.create(AFFINE_NIELS_SIZE)
local MULG_DUMMY_POINT = buffer.create(POINT_SIZE)
local MULG_P1X = buffer.create(COORD_SIZE)
local MULG_P1Y = buffer.create(COORD_SIZE)
local MULG_P1Z = buffer.create(COORD_SIZE)
local MULG_P1T = buffer.create(COORD_SIZE)
local MULG_N2P = buffer.create(COORD_SIZE)
local MULG_N2M = buffer.create(COORD_SIZE)
local MULG_N2T = buffer.create(COORD_SIZE)
local MULG_TMP = buffer.create(COORD_SIZE)

local NAF_TABLE_DOUBLED = buffer.create(POINT_SIZE)
local NAF_TABLE_P1X = buffer.create(COORD_SIZE)
local NAF_TABLE_P1Y = buffer.create(COORD_SIZE)
local NAF_TABLE_P1Z = buffer.create(COORD_SIZE)
local NAF_TABLE_P1T = buffer.create(COORD_SIZE)
local NAF_TABLE_N2P = buffer.create(COORD_SIZE)
local NAF_TABLE_N2M = buffer.create(COORD_SIZE)
local NAF_TABLE_N2Z = buffer.create(COORD_SIZE)
local NAF_TABLE_N2T = buffer.create(COORD_SIZE)
local NAF_TABLE_TMP = buffer.create(COORD_SIZE)
local NAF_TABLE_DBL_P = buffer.create(COORD_SIZE)
local NAF_TABLE_DBL_M = buffer.create(COORD_SIZE)
local NAF_TABLE_DBL_Z = buffer.create(COORD_SIZE)
local NAF_TABLE_DBL_T = buffer.create(COORD_SIZE)

local NAF_OUTPUT = buffer.create(512 * 8)
local RADIX_OUTPUT = buffer.create(272 * 8)

local BASEPONT_G: buffer? = nil
local AFFINE_BASEPOINT_TABLE: buffer? = nil

local function GetCoord(Point: buffer, Index: number, Storage: buffer?): buffer
	local Coord = Storage or buffer.create(COORD_SIZE)
	buffer.copy(Coord, 0, Point, Index * COORD_SIZE, COORD_SIZE)
	return Coord
end

Edwards25519 = {}

function Edwards25519.Double(Point1: buffer, Storage: buffer?): buffer
	local Point1X = GetCoord(Point1, 0, COORD_BUFFER_0)
	local Point1Y = GetCoord(Point1, 1, COORD_BUFFER_1)
	local Point1Z = GetCoord(Point1, 2, COORD_BUFFER_2)

	local SquaredA = FieldPrime.Square(Point1X)
	local SquaredB = FieldPrime.Square(Point1Y)
	FieldPrime.Square(Point1Z, Point1Z)
	FieldPrime.Add(Point1Z, Point1Z, Point1Z)
	local DoubledD = Point1Z
	local SumE = FieldPrime.Add(SquaredA, SquaredB)
	FieldPrime.Add(Point1X, Point1Y, Point1X)
	local SumF = Point1X
	local SquaredG = FieldPrime.Square(SumF)
	FieldPrime.Sub(SquaredG, SumE, SquaredG)
	FieldPrime.Carry(SquaredG, SquaredG)
	local DiffH = SquaredG
	FieldPrime.Sub(SquaredB, SquaredA, SquaredB)
	local DiffI = SquaredB
	FieldPrime.Sub(DoubledD, DiffI, DoubledD)
	FieldPrime.Carry(DoubledD, DoubledD)
	local DiffJ = DoubledD

	local NewX = FieldPrime.Mul(DiffH, DiffJ)
	local NewY = FieldPrime.Mul(DiffI, SumE)
	FieldPrime.Mul(DiffJ, DiffI, DiffJ)
	local NewZ = DiffJ
	FieldPrime.Mul(DiffH, SumE, DiffH)
	local NewT = DiffH

	local Result = Storage or buffer.create(POINT_SIZE)
	buffer.copy(Result, 0 * COORD_SIZE, NewX, 0, COORD_SIZE)
	buffer.copy(Result, 1 * COORD_SIZE, NewY, 0, COORD_SIZE)
	buffer.copy(Result, 2 * COORD_SIZE, NewZ, 0, COORD_SIZE)
	buffer.copy(Result, 3 * COORD_SIZE, NewT, 0, COORD_SIZE)

	return Result
end

function Edwards25519.Add(Point1: buffer, NielsPoint2: buffer, Storage: buffer?): buffer
	local Point1X = GetCoord(Point1, 0, COORD_BUFFER_0)
	local Point1Y = GetCoord(Point1, 1, COORD_BUFFER_1)
	local Point1Z = GetCoord(Point1, 2, COORD_BUFFER_2)
	local Point1T = GetCoord(Point1, 3, COORD_BUFFER_3)

	local Niels1Plus = GetCoord(NielsPoint2, 0, COORD_BUFFER_4)
	local Niels1Minus = GetCoord(NielsPoint2, 1, COORD_BUFFER_5)
	local Niels1Z = GetCoord(NielsPoint2, 2, COORD_BUFFER_6)
	local Niels1T = GetCoord(NielsPoint2, 3, COORD_BUFFER_7)

	local DiffA = FieldPrime.Sub(Point1Y, Point1X)
	FieldPrime.Mul(DiffA, Niels1Minus, DiffA)
	local ProductB = DiffA

	local SumC = FieldPrime.Add(Point1Y, Point1X)
	FieldPrime.Mul(SumC, Niels1Plus, SumC)
	local ProductD = SumC

	FieldPrime.Mul(Point1T, Niels1T, Point1T)
	local ProductE = Point1T

	FieldPrime.Mul(Point1Z, Niels1Z, Point1Z)
	local ProductF = Point1Z

	local DiffG = FieldPrime.Sub(ProductD, ProductB)
	local DiffH = FieldPrime.Sub(ProductF, ProductE)

	FieldPrime.Add(ProductF, ProductE, ProductF)
	local SumI = ProductF

	FieldPrime.Add(ProductD, ProductB, ProductD)
	local SumJ = ProductD

	local NewX = FieldPrime.Mul(DiffG, DiffH)
	local NewY = FieldPrime.Mul(SumI, SumJ)
	FieldPrime.Mul(DiffH, SumI, DiffH)
	local NewZ = DiffH
	FieldPrime.Mul(DiffG, SumJ, DiffG)
	local NewT = DiffG

	local Result = Storage or buffer.create(POINT_SIZE)
	buffer.copy(Result, 0 * COORD_SIZE, NewX, 0, COORD_SIZE)
	buffer.copy(Result, 1 * COORD_SIZE, NewY, 0, COORD_SIZE)
	buffer.copy(Result, 2 * COORD_SIZE, NewZ, 0, COORD_SIZE)
	buffer.copy(Result, 3 * COORD_SIZE, NewT, 0, COORD_SIZE)

	return Result
end

function Edwards25519.Sub(Point1: buffer, NielsPoint2: buffer, Storage: buffer?): buffer
	local Point1X = GetCoord(Point1, 0, COORD_BUFFER_0)
	local Point1Y = GetCoord(Point1, 1, COORD_BUFFER_1)
	local Point1Z = GetCoord(Point1, 2, COORD_BUFFER_2)
	local Point1T = GetCoord(Point1, 3, COORD_BUFFER_3)

	local Niels1Plus = GetCoord(NielsPoint2, 0, COORD_BUFFER_4)
	local Niels1Minus = GetCoord(NielsPoint2, 1, COORD_BUFFER_5)
	local Niels1Z = GetCoord(NielsPoint2, 2, COORD_BUFFER_6)
	local Niels1T = GetCoord(NielsPoint2, 3, COORD_BUFFER_7)

	local DiffA = FieldPrime.Sub(Point1Y, Point1X)
	FieldPrime.Mul(DiffA, Niels1Plus, DiffA)
	local ProductB = DiffA
	FieldPrime.Add(Point1Y, Point1X, Point1Y)
	local SumC = Point1Y
	FieldPrime.Mul(SumC, Niels1Minus, SumC)
	local ProductD = SumC
	FieldPrime.Mul(Point1T, Niels1T, Point1T)
	local ProductE = Point1T
	FieldPrime.Mul(Point1Z, Niels1Z, Point1Z)
	local ProductF = Point1Z
	local DiffG = FieldPrime.Sub(ProductD, ProductB)
	local SumH = FieldPrime.Add(ProductF, ProductE)
	local DiffI = FieldPrime.Sub(ProductF, ProductE)
	FieldPrime.Add(ProductD, ProductB, ProductD)
	local SumJ = ProductD

	local NewX = FieldPrime.Mul(DiffG, SumH)
	local NewY = FieldPrime.Mul(DiffI, SumJ)
	FieldPrime.Mul(SumH, DiffI, SumH)
	local NewZ = SumH
	FieldPrime.Mul(DiffG, SumJ, DiffG)
	local NewT = DiffG

	local Result = Storage or buffer.create(POINT_SIZE)
	buffer.copy(Result, 0 * COORD_SIZE, NewX, 0, COORD_SIZE)
	buffer.copy(Result, 1 * COORD_SIZE, NewY, 0, COORD_SIZE)
	buffer.copy(Result, 2 * COORD_SIZE, NewZ, 0, COORD_SIZE)
	buffer.copy(Result, 3 * COORD_SIZE, NewT, 0, COORD_SIZE)

	return Result
end

function Edwards25519.Niels(Point1: buffer, Storage: buffer?): buffer
	local Point1X = GetCoord(Point1, 0, COORD_BUFFER_0)
	local Point1Y = GetCoord(Point1, 1, COORD_BUFFER_1)
	local Point1Z = GetCoord(Point1, 2, COORD_BUFFER_2)
	local Point1T = GetCoord(Point1, 3, COORD_BUFFER_3)

	local PlusN3 = FieldPrime.Add(Point1Y, Point1X)
	local MinusN3 = FieldPrime.Sub(Point1Y, Point1X)
	FieldPrime.Add(Point1Z, Point1Z, Point1Z)
	local DoubledN3Z = Point1Z
	FieldPrime.Mul(Point1T, CURVE_K, Point1T)
	local ScaledN3T = Point1T

	local Result = Storage or buffer.create(POINT_SIZE)
	buffer.copy(Result, 0 * COORD_SIZE, PlusN3, 0, COORD_SIZE)
	buffer.copy(Result, 1 * COORD_SIZE, MinusN3, 0, COORD_SIZE)
	buffer.copy(Result, 2 * COORD_SIZE, DoubledN3Z, 0, COORD_SIZE)
	buffer.copy(Result, 3 * COORD_SIZE, ScaledN3T, 0, COORD_SIZE)

	return Result
end

function Edwards25519.AffineNiels(Point1: buffer, Storage: buffer?): buffer
	local Point1X = GetCoord(Point1, 0, COORD_BUFFER_0)
	local Point1Y = GetCoord(Point1, 1, COORD_BUFFER_1)
	local Point1T = GetCoord(Point1, 3, COORD_BUFFER_3)

	local YPlusX = FieldPrime.Add(Point1Y, Point1X)
	local YMinusX = FieldPrime.Sub(Point1Y, Point1X)
	FieldPrime.Mul(Point1T, CURVE_K, Point1T)
	local T2d = Point1T

	local Result = Storage or buffer.create(AFFINE_NIELS_SIZE)
	buffer.copy(Result, 0 * COORD_SIZE, YPlusX, 0, COORD_SIZE)
	buffer.copy(Result, 1 * COORD_SIZE, YMinusX, 0, COORD_SIZE)
	buffer.copy(Result, 2 * COORD_SIZE, T2d, 0, COORD_SIZE)

	return Result
end

function Edwards25519.AddAffine(Point1: buffer, AffineNiels2: buffer, Storage: buffer?): buffer
	local Point1X = GetCoord(Point1, 0, COORD_BUFFER_0)
	local Point1Y = GetCoord(Point1, 1, COORD_BUFFER_1)
	local Point1Z = GetCoord(Point1, 2, COORD_BUFFER_2)
	local Point1T = GetCoord(Point1, 3, COORD_BUFFER_3)

	local Niels2YPlusX = GetCoord(AffineNiels2, 0, COORD_BUFFER_4)
	local Niels2YMinusX = GetCoord(AffineNiels2, 1, COORD_BUFFER_5)
	local Niels2T2d = GetCoord(AffineNiels2, 2, COORD_BUFFER_6)

	local DiffA = FieldPrime.Sub(Point1Y, Point1X)
	FieldPrime.Mul(DiffA, Niels2YMinusX, DiffA)
	local ProductB = DiffA

	local SumC = FieldPrime.Add(Point1Y, Point1X)
	FieldPrime.Mul(SumC, Niels2YPlusX, SumC)
	local ProductD = SumC

	FieldPrime.Mul(Point1T, Niels2T2d, Point1T)
	local ProductE = Point1T

	FieldPrime.Add(Point1Z, Point1Z, Point1Z)
	local ProductF = Point1Z

	local DiffG = FieldPrime.Sub(ProductD, ProductB)
	local DiffH = FieldPrime.Sub(ProductF, ProductE)

	FieldPrime.Add(ProductF, ProductE, ProductF)
	local SumI = ProductF

	FieldPrime.Add(ProductD, ProductB, ProductD)
	local SumJ = ProductD

	local NewX = FieldPrime.Mul(DiffG, DiffH)
	local NewY = FieldPrime.Mul(SumI, SumJ)
	FieldPrime.Mul(DiffH, SumI, DiffH)
	local NewZ = DiffH
	FieldPrime.Mul(DiffG, SumJ, DiffG)
	local NewT = DiffG

	local Result = Storage or buffer.create(POINT_SIZE)
	buffer.copy(Result, 0 * COORD_SIZE, NewX, 0, COORD_SIZE)
	buffer.copy(Result, 1 * COORD_SIZE, NewY, 0, COORD_SIZE)
	buffer.copy(Result, 2 * COORD_SIZE, NewZ, 0, COORD_SIZE)
	buffer.copy(Result, 3 * COORD_SIZE, NewT, 0, COORD_SIZE)

	return Result
end

function Edwards25519.SubAffine(Point1: buffer, AffineNiels2: buffer, Storage: buffer?): buffer
	local Point1X = GetCoord(Point1, 0, COORD_BUFFER_0)
	local Point1Y = GetCoord(Point1, 1, COORD_BUFFER_1)
	local Point1Z = GetCoord(Point1, 2, COORD_BUFFER_2)
	local Point1T = GetCoord(Point1, 3, COORD_BUFFER_3)

	local Niels2YPlusX = GetCoord(AffineNiels2, 0, COORD_BUFFER_4)
	local Niels2YMinusX = GetCoord(AffineNiels2, 1, COORD_BUFFER_5)
	local Niels2T2d = GetCoord(AffineNiels2, 2, COORD_BUFFER_6)

	local DiffA = FieldPrime.Sub(Point1Y, Point1X)
	FieldPrime.Mul(DiffA, Niels2YPlusX, DiffA)
	local ProductB = DiffA

	FieldPrime.Add(Point1Y, Point1X, Point1Y)
	local SumC = Point1Y
	FieldPrime.Mul(SumC, Niels2YMinusX, SumC)
	local ProductD = SumC

	FieldPrime.Mul(Point1T, Niels2T2d, Point1T)
	local ProductE = Point1T

	FieldPrime.Add(Point1Z, Point1Z, Point1Z)
	local ProductF = Point1Z

	local DiffG = FieldPrime.Sub(ProductD, ProductB)
	local SumH = FieldPrime.Add(ProductF, ProductE)
	local DiffI = FieldPrime.Sub(ProductF, ProductE)
	FieldPrime.Add(ProductD, ProductB, ProductD)
	local SumJ = ProductD

	local NewX = FieldPrime.Mul(DiffG, SumH)
	local NewY = FieldPrime.Mul(DiffI, SumJ)
	FieldPrime.Mul(SumH, DiffI, SumH)
	local NewZ = SumH
	FieldPrime.Mul(DiffG, SumJ, DiffG)
	local NewT = DiffG

	local Result = Storage or buffer.create(POINT_SIZE)
	buffer.copy(Result, 0 * COORD_SIZE, NewX, 0, COORD_SIZE)
	buffer.copy(Result, 1 * COORD_SIZE, NewY, 0, COORD_SIZE)
	buffer.copy(Result, 2 * COORD_SIZE, NewZ, 0, COORD_SIZE)
	buffer.copy(Result, 3 * COORD_SIZE, NewT, 0, COORD_SIZE)

	return Result
end

function Edwards25519.Scale(Point1: buffer): buffer
	local Point1X = GetCoord(Point1, 0, COORD_BUFFER_0)
	local Point1Y = GetCoord(Point1, 1, COORD_BUFFER_1)
	local Point1Z = GetCoord(Point1, 2, COORD_BUFFER_2)

	FieldPrime.Invert(Point1Z, Point1Z)
	local ZInverse = Point1Z
	FieldPrime.Mul(Point1X, ZInverse, Point1X)
	local NewX = Point1X
	FieldPrime.Mul(Point1Y, ZInverse, Point1Y)
	local NewY = Point1Y
	local NewZ = FieldPrime.Num(1)
	local NewT = FieldPrime.Mul(NewX, NewY)

	local Result = buffer.create(POINT_SIZE)
	buffer.copy(Result, 0 * COORD_SIZE, NewX, 0, COORD_SIZE)
	buffer.copy(Result, 1 * COORD_SIZE, NewY, 0, COORD_SIZE)
	buffer.copy(Result, 2 * COORD_SIZE, NewZ, 0, COORD_SIZE)
	buffer.copy(Result, 3 * COORD_SIZE, NewT, 0, COORD_SIZE)

	return Result
end

function Edwards25519.Encode(Point1: buffer): buffer
	local ScaledPoint = Edwards25519.Scale(Point1)
	local Point1X = GetCoord(ScaledPoint, 0, COORD_BUFFER_0)
	local Point1Y = GetCoord(ScaledPoint, 1, COORD_BUFFER_1)

	local EncodedY = FieldPrime.Encode(Point1Y)
	local CanonicalX = FieldPrime.Canonicalize(Point1X)
	local XSignBit = buffer.readf64(CanonicalX, 0) % 2

	local ResultBuffer = buffer.create(32)
	buffer.copy(ResultBuffer, 0, EncodedY, 0, 32)

	local LastByte = buffer.readu8(ResultBuffer, 31)
	buffer.writeu8(ResultBuffer, 31, LastByte + XSignBit * 128)

	return ResultBuffer
end

function Edwards25519.Decode(EncodedBuffer: buffer): buffer?
	local WorkingBuffer = buffer.create(32)
	buffer.copy(WorkingBuffer, 0, EncodedBuffer, 0, 32)

	local LastByte = buffer.readu8(WorkingBuffer, 31)
	local SignBit = bit32.extract(LastByte, 7)
	buffer.writeu8(WorkingBuffer, 31, bit32.band(LastByte, 0x7F))

	local YCoord = FieldPrime.Decode(WorkingBuffer)
	local YSquared = FieldPrime.Square(YCoord)
	local Numerator = FieldPrime.Sub(YSquared, FieldPrime.Num(1))
	local Denominator = FieldPrime.Mul(YSquared, CURVE_D)
	local DenomPlusOne = FieldPrime.Add(Denominator, FieldPrime.Num(1))

	local XCoord = FieldPrime.SqrtDiv(Numerator, DenomPlusOne)
	if not XCoord then
		return nil
	end

	local CanonicalX = FieldPrime.Canonicalize(XCoord)
	local XSignBit = buffer.readf64(CanonicalX, 0) % 2

	if XSignBit ~= SignBit then
		XCoord = FieldPrime.Carry(FieldPrime.Neg(XCoord))
	end

	local ZCoord = FieldPrime.Num(1)
	local TCoord = FieldPrime.Mul(XCoord, YCoord)

	local Result = buffer.create(POINT_SIZE)
	buffer.copy(Result, 0 * COORD_SIZE, XCoord, 0, COORD_SIZE)
	buffer.copy(Result, 1 * COORD_SIZE, YCoord, 0, COORD_SIZE)
	buffer.copy(Result, 2 * COORD_SIZE, ZCoord, 0, COORD_SIZE)
	buffer.copy(Result, 3 * COORD_SIZE, TCoord, 0, COORD_SIZE)

	return Result
end

local BASEPOINT_BYTES = buffer.create(32) do
	local BasePointHex = {
		0x58, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
		0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
		0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
		0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
	}

	for Index = 1, 32 do
		buffer.writeu8(BASEPOINT_BYTES, Index - 1, BasePointHex[Index])
	end

	BASEPONT_G = Edwards25519.Decode(BASEPOINT_BYTES)
end

function Edwards25519.AffineRadixWTable(BasePoint: buffer, RadixWidth: number): buffer
	if RadixWidth <= 0 or RadixWidth > 8 then
		error("Invalid Radix width", 2)
	end

	if buffer.len(BasePoint) ~= POINT_SIZE then
		error("Invalid Basepoint", 2)
	end

	local MaxWindows = math.ceil(256 / RadixWidth)
	local MaxRowSize = 2 ^ RadixWidth / 2

	local TableData = buffer.create(MaxWindows * MaxRowSize * AFFINE_NIELS_SIZE)

	local CurrentBasePoint = buffer.create(POINT_SIZE)
	buffer.copy(CurrentBasePoint, 0, BasePoint, 0, POINT_SIZE)

	local AffineNiels = Edwards25519.AffineNiels
	local Add = Edwards25519.Add
	local Double = Edwards25519.Double
	local Scale = Edwards25519.Scale
	local Niels = Edwards25519.Niels
	local NielsSize = AFFINE_NIELS_SIZE

	for WindowIndex = 1, MaxWindows do
		local BaseOffset = ((WindowIndex - 1) * MaxRowSize * NielsSize)
		local WorkingPoint = buffer.create(POINT_SIZE)
		buffer.copy(WorkingPoint, 0, CurrentBasePoint, 0, POINT_SIZE)

		local ScaledPoint = Scale(WorkingPoint)
		local FirstAffineNiels = AffineNiels(ScaledPoint)
		buffer.copy(TableData, BaseOffset, FirstAffineNiels, 0, NielsSize)

		local FirstNiels = Niels(ScaledPoint)

		for Multiple = 2, MaxRowSize do
			Add(WorkingPoint, FirstNiels, WorkingPoint)
			local Scaled = Scale(WorkingPoint)
			local AffineNielsBuffer = AffineNiels(Scaled)

			local Offset = BaseOffset + ((Multiple - 1) * NielsSize)
			buffer.copy(TableData, Offset, AffineNielsBuffer, 0, NielsSize)
		end

		for _ = 1, RadixWidth do
			CurrentBasePoint = Double(CurrentBasePoint)
		end
	end

	return TableData
end

do
	if BASEPONT_G then
		AFFINE_BASEPOINT_TABLE = Edwards25519.AffineRadixWTable(BASEPONT_G, BASE_RADIX_WIDTH)
	end
end

function Edwards25519.GetAffineBasePointTableEntry(WindowIndex: number, Multiple: number, Storage: buffer?): buffer
	if not AFFINE_BASEPOINT_TABLE then
		return buffer.create(0)
	end

	local BaseOffset = ((WindowIndex - 1) * BASE_POINT_ROW * AFFINE_NIELS_SIZE)
	local Offset = BaseOffset + ((Multiple - 1) * AFFINE_NIELS_SIZE)

	local AffineNielsPoint = Storage or buffer.create(AFFINE_NIELS_SIZE)
	buffer.copy(AffineNielsPoint, 0, AFFINE_BASEPOINT_TABLE, Offset, AFFINE_NIELS_SIZE)

	return AffineNielsPoint
end

function Edwards25519.SignedRadixW(ScalarBits: buffer, ScalarBitCount: number, RadixWidth: number): (buffer, number)
	if ScalarBitCount <= 0 or ScalarBitCount > 256 then
		error("Invalid scalar bit count", 2)
	end

	if RadixWidth <= 0 or RadixWidth > 8 then
		error("Invalid Radix width", 2)
	end

	local RadixValue = 2 ^ RadixWidth
	local HalfRadix = RadixValue / 2
	local MaxOutputLength = 272
	local OutputDigits = RADIX_OUTPUT
	local OutputLength, Accumulator = 0, 0
	local Multiplier = 1

	for BitIndex = 1, ScalarBitCount do
		if BitIndex > ScalarBitCount then
			break
		end

		local BitValue = buffer.readf64(ScalarBits, (BitIndex - 1) * 8)
		Accumulator += BitValue * Multiplier
		Multiplier *= 2

		while BitIndex == ScalarBitCount and Accumulator > 0 or Multiplier > RadixValue do
			if OutputLength >= MaxOutputLength then
				error("Output overflow in SignedRadixW")
			end

			local Remainder = Accumulator % RadixValue
			if Remainder >= HalfRadix then
				Remainder -= RadixValue
			end
			Accumulator = (Accumulator - Remainder) / RadixValue
			Multiplier /= RadixValue
			buffer.writef64(OutputDigits, OutputLength * 8, Remainder)
			OutputLength += 1
		end
	end

	return OutputDigits, OutputLength
end

function Edwards25519.WindowedNAF(ScalarBits: buffer, ScalarBitCount: number, WindowWidth: number): (buffer, number)
	local WindowValue = 2 ^ WindowWidth
	local HalfWindow = WindowValue / 2
	local OutputNAF = NAF_OUTPUT
	local OutputLength = 0
	local Accumulator = 0
	local Multiplier = 1

	for BitIndex = 1, ScalarBitCount do
		local BitValue = buffer.readf64(ScalarBits, (BitIndex - 1) * 8)
		Accumulator += BitValue * Multiplier
		Multiplier *= 2

		while BitIndex == ScalarBitCount and Accumulator > 0 or Multiplier > WindowValue do
			if Accumulator % 2 == 0 then
				Accumulator /= 2
				Multiplier /= 2
				buffer.writef64(OutputNAF, OutputLength * 8, 0)
				OutputLength += 1
			else
				local Remainder = Accumulator % WindowValue
				if Remainder >= HalfWindow then
					Remainder -= WindowValue
				end
				Accumulator -= Remainder
				buffer.writef64(OutputNAF, OutputLength * 8, Remainder)
				OutputLength += 1
			end
		end
	end

	while OutputLength > 0 and buffer.readf64(OutputNAF, (OutputLength - 1) * 8) == 0 do
		OutputLength -= 1
	end

	return OutputNAF, OutputLength
end

function Edwards25519.WindowedNAFTable(BasePoint: buffer, WindowWidth: number): buffer
	local PointSize = POINT_SIZE
	local CoordSize = COORD_SIZE
	local CurveK = CURVE_K
	local MaxOddMultiples = 2 ^ WindowWidth

	Edwards25519.Double(BasePoint, NAF_TABLE_DOUBLED)

	local TableData = buffer.create(MaxOddMultiples * PointSize)

	local FAdd = FieldPrime.Add
	local FSub = FieldPrime.Sub
	local FMul = FieldPrime.Mul

	local P1X = NAF_TABLE_P1X
	local P1Y = NAF_TABLE_P1Y
	local P1Z = NAF_TABLE_P1Z
	local P1T = NAF_TABLE_P1T
	local N2P = NAF_TABLE_N2P
	local N2M = NAF_TABLE_N2M
	local N2Z = NAF_TABLE_N2Z
	local N2T = NAF_TABLE_N2T
	local TMP = NAF_TABLE_TMP
	local DBLP = NAF_TABLE_DBL_P
	local DBLM = NAF_TABLE_DBL_M
	local DBLZ = NAF_TABLE_DBL_Z
	local DBLT = NAF_TABLE_DBL_T
	local Doubled = NAF_TABLE_DOUBLED

	buffer.copy(P1X, 0, Doubled, 0, CoordSize)
	buffer.copy(P1Y, 0, Doubled, CoordSize, CoordSize)
	buffer.copy(P1Z, 0, Doubled, 2 * CoordSize, CoordSize)
	buffer.copy(P1T, 0, Doubled, 3 * CoordSize, CoordSize)

	FAdd(P1Y, P1X, DBLP)
	FSub(P1Y, P1X, DBLM)
	FAdd(P1Z, P1Z, DBLZ)
	FMul(P1T, CurveK, DBLT)

	buffer.copy(P1X, 0, BasePoint, 0, CoordSize)
	buffer.copy(P1Y, 0, BasePoint, CoordSize, CoordSize)
	buffer.copy(P1Z, 0, BasePoint, 2 * CoordSize, CoordSize)
	buffer.copy(P1T, 0, BasePoint, 3 * CoordSize, CoordSize)

	FAdd(P1Y, P1X, N2P)
	FSub(P1Y, P1X, N2M)
	FAdd(P1Z, P1Z, N2Z)
	FMul(P1T, CurveK, N2T)

	buffer.copy(TableData, 0, N2P, 0, CoordSize)
	buffer.copy(TableData, CoordSize, N2M, 0, CoordSize)
	buffer.copy(TableData, 2 * CoordSize, N2Z, 0, CoordSize)
	buffer.copy(TableData, 3 * CoordSize, N2T, 0, CoordSize)

	buffer.copy(P1X, 0, BasePoint, 0, CoordSize)
	buffer.copy(P1Y, 0, BasePoint, CoordSize, CoordSize)
	buffer.copy(P1Z, 0, BasePoint, 2 * CoordSize, CoordSize)
	buffer.copy(P1T, 0, BasePoint, 3 * CoordSize, CoordSize)

	for OddMultiple = 3, MaxOddMultiples, 2 do
		local CurrentOffset = ((OddMultiple - 1) * PointSize)

		FSub(P1Y, P1X, TMP)
		FMul(TMP, DBLM, TMP)
		FAdd(P1Y, P1X, N2P)
		FMul(N2P, DBLP, N2P)
		FMul(P1T, DBLT, P1T)
		FMul(P1Z, DBLZ, P1Z)

		FSub(N2P, TMP, N2M)
		FSub(P1Z, P1T, N2Z)
		FAdd(P1Z, P1T, P1Z)
		FAdd(N2P, TMP, N2P)

		FMul(N2M, N2Z, P1X)
		FMul(P1Z, N2P, P1Y)
		FMul(N2Z, P1Z, P1Z)
		FMul(N2M, N2P, P1T)

		FAdd(P1Y, P1X, N2P)
		FSub(P1Y, P1X, N2M)
		FAdd(P1Z, P1Z, N2Z)
		FMul(P1T, CurveK, N2T)

		buffer.copy(TableData, CurrentOffset, N2P, 0, CoordSize)
		buffer.copy(TableData, CurrentOffset + CoordSize, N2M, 0, CoordSize)
		buffer.copy(TableData, CurrentOffset + 2 * CoordSize, N2Z, 0, CoordSize)
		buffer.copy(TableData, CurrentOffset + 3 * CoordSize, N2T, 0, CoordSize)
	end

	return TableData
end

function Edwards25519.MulG(ScalarBits: buffer, ScalarBitCount: number): buffer
	local PointSize = POINT_SIZE
	local CoordSize = COORD_SIZE
	local AffineNielsSize = AFFINE_NIELS_SIZE
	local IdentityO = IDENTITY_O
	local BaseRadixWidth = BASE_RADIX_WIDTH
	local BasePointRow = BASE_POINT_ROW
	local AffineTable = AFFINE_BASEPOINT_TABLE :: buffer

	local SignedWindows, WindowCount = Edwards25519.SignedRadixW(ScalarBits, ScalarBitCount, BaseRadixWidth)

	local ResultPoint = MULG_RESULT_POINT
	buffer.copy(ResultPoint, 0, IdentityO, 0, PointSize)

	local AffineNielsPoint = MULG_AFFINE_NIELS
	local DummyPoint = MULG_DUMMY_POINT
	buffer.copy(DummyPoint, 0, IdentityO, 0, PointSize)

	local FAdd = FieldPrime.Add
	local FSub = FieldPrime.Sub
	local FMul = FieldPrime.Mul

	local P1X = MULG_P1X
	local P1Y = MULG_P1Y
	local P1Z = MULG_P1Z
	local P1T = MULG_P1T
	local N2P = MULG_N2P
	local N2M = MULG_N2M
	local N2T = MULG_N2T
	local TMP = MULG_TMP

	for WindowIndex = 1, WindowCount do
		local WindowValue = buffer.readf64(SignedWindows, (WindowIndex - 1) * 8)

		if WindowValue > 0 then
			local BaseOffset = ((WindowIndex - 1) * BasePointRow * AffineNielsSize)
			local Offset = BaseOffset + ((WindowValue - 1) * AffineNielsSize)
			buffer.copy(AffineNielsPoint, 0, AffineTable, Offset, AffineNielsSize)

			buffer.copy(P1X, 0, ResultPoint, 0, CoordSize)
			buffer.copy(P1Y, 0, ResultPoint, CoordSize, CoordSize)
			buffer.copy(P1Z, 0, ResultPoint, 2 * CoordSize, CoordSize)
			buffer.copy(P1T, 0, ResultPoint, 3 * CoordSize, CoordSize)
			buffer.copy(N2P, 0, AffineNielsPoint, 0, CoordSize)
			buffer.copy(N2M, 0, AffineNielsPoint, CoordSize, CoordSize)
			buffer.copy(N2T, 0, AffineNielsPoint, 2 * CoordSize, CoordSize)

			FSub(P1Y, P1X, TMP)
			FMul(TMP, N2M, TMP)
			FAdd(P1Y, P1X, P1X)
			FMul(P1X, N2P, P1X)
			FMul(P1T, N2T, P1T)
			FAdd(P1Z, P1Z, P1Z)

			FSub(P1X, TMP, P1Y)
			FSub(P1Z, P1T, N2P)
			FAdd(P1Z, P1T, P1Z)
			FAdd(P1X, TMP, P1X)

			FMul(P1Y, N2P, TMP)
			FMul(P1Z, P1X, P1T)
			FMul(N2P, P1Z, P1Z)
			FMul(P1Y, P1X, P1X)

			buffer.copy(ResultPoint, 0, TMP, 0, CoordSize)
			buffer.copy(ResultPoint, CoordSize, P1T, 0, CoordSize)
			buffer.copy(ResultPoint, 2 * CoordSize, P1Z, 0, CoordSize)
			buffer.copy(ResultPoint, 3 * CoordSize, P1X, 0, CoordSize)

		elseif WindowValue < 0 then
			local BaseOffset = ((WindowIndex - 1) * BasePointRow * AffineNielsSize)
			local Offset = BaseOffset + (((-WindowValue) - 1) * AffineNielsSize)
			buffer.copy(AffineNielsPoint, 0, AffineTable, Offset, AffineNielsSize)

			buffer.copy(P1X, 0, ResultPoint, 0, CoordSize)
			buffer.copy(P1Y, 0, ResultPoint, CoordSize, CoordSize)
			buffer.copy(P1Z, 0, ResultPoint, 2 * CoordSize, CoordSize)
			buffer.copy(P1T, 0, ResultPoint, 3 * CoordSize, CoordSize)
			buffer.copy(N2P, 0, AffineNielsPoint, 0, CoordSize)
			buffer.copy(N2M, 0, AffineNielsPoint, CoordSize, CoordSize)
			buffer.copy(N2T, 0, AffineNielsPoint, 2 * CoordSize, CoordSize)

			FSub(P1Y, P1X, TMP)
			FMul(TMP, N2P, TMP)
			FAdd(P1Y, P1X, P1X)
			FMul(P1X, N2M, P1X)
			FMul(P1T, N2T, P1T)
			FAdd(P1Z, P1Z, P1Z)

			FSub(P1X, TMP, P1Y)
			FAdd(P1Z, P1T, N2P)
			FSub(P1Z, P1T, P1Z)
			FAdd(P1X, TMP, P1X)

			FMul(P1Y, N2P, TMP)
			FMul(P1Z, P1X, P1T)
			FMul(N2P, P1Z, P1Z)
			FMul(P1Y, P1X, P1X)

			buffer.copy(ResultPoint, 0, TMP, 0, CoordSize)
			buffer.copy(ResultPoint, CoordSize, P1T, 0, CoordSize)
			buffer.copy(ResultPoint, 2 * CoordSize, P1Z, 0, CoordSize)
			buffer.copy(ResultPoint, 3 * CoordSize, P1X, 0, CoordSize)

		else
			local BaseOffset = ((WindowIndex - 1) * BasePointRow * AffineNielsSize)
			buffer.copy(AffineNielsPoint, 0, AffineTable, BaseOffset, AffineNielsSize)

			buffer.copy(P1X, 0, DummyPoint, 0, CoordSize)
			buffer.copy(P1Y, 0, DummyPoint, CoordSize, CoordSize)
			buffer.copy(P1Z, 0, DummyPoint, 2 * CoordSize, CoordSize)
			buffer.copy(P1T, 0, DummyPoint, 3 * CoordSize, CoordSize)
			buffer.copy(N2P, 0, AffineNielsPoint, 0, CoordSize)
			buffer.copy(N2M, 0, AffineNielsPoint, CoordSize, CoordSize)
			buffer.copy(N2T, 0, AffineNielsPoint, 2 * CoordSize, CoordSize)

			FSub(P1Y, P1X, TMP)
			FMul(TMP, N2M, TMP)
			FAdd(P1Y, P1X, P1X)
			FMul(P1X, N2P, P1X)
			FMul(P1T, N2T, P1T)
			FAdd(P1Z, P1Z, P1Z)

			FSub(P1X, TMP, P1Y)
			FSub(P1Z, P1T, N2P)
			FAdd(P1Z, P1T, P1Z)
			FAdd(P1X, TMP, P1X)

			FMul(P1Y, N2P, TMP)
			FMul(P1Z, P1X, P1T)
			FMul(N2P, P1Z, P1Z)
			FMul(P1Y, P1X, P1X)

			buffer.copy(DummyPoint, 0, TMP, 0, CoordSize)
			buffer.copy(DummyPoint, CoordSize, P1T, 0, CoordSize)
			buffer.copy(DummyPoint, 2 * CoordSize, P1Z, 0, CoordSize)
			buffer.copy(DummyPoint, 3 * CoordSize, P1X, 0, CoordSize)
		end
	end

	local Output = buffer.create(PointSize)
	buffer.copy(Output, 0, ResultPoint, 0, PointSize)
	return Output
end

function Edwards25519.Mul(BasePoint: buffer, ScalarBits: buffer, ScalarBitCount: number): buffer
	local PointSize = POINT_SIZE
	local CoordSize = COORD_SIZE
	local IdentityO = IDENTITY_O

	local NAFForm, NAFLength = Edwards25519.WindowedNAF(ScalarBits, ScalarBitCount, 5)
	local MultipleTable = Edwards25519.WindowedNAFTable(BasePoint, 5)

	local ResultPoint = MUL_RESULT_POINT
	buffer.copy(ResultPoint, 0, IdentityO, 0, PointSize)

	local NielsPoint = MUL_NIELS_POINT

	local Square = FieldPrime.Square
	local FAdd = FieldPrime.Add
	local FSub = FieldPrime.Sub
	local FMul = FieldPrime.Mul
	local Carry = FieldPrime.Carry

	local DoubleX = MUL_DOUBLE_X
	local DoubleY = MUL_DOUBLE_Y
	local DoubleZ = MUL_DOUBLE_Z
	local DoubleA = MUL_DOUBLE_A
	local DoubleB = MUL_DOUBLE_B
	local DoubleE = MUL_DOUBLE_E
	local DoubleG = MUL_DOUBLE_G

	local P1X = MUL_P1X
	local P1Y = MUL_P1Y
	local P1Z = MUL_P1Z
	local P1T = MUL_P1T
	local N2P = MUL_N2P
	local N2M = MUL_N2M
	local N2Z = MUL_N2Z
	local N2T = MUL_N2T
	local TMP = MUL_TMP

	for NAFIndex = NAFLength, 1, -1 do
		local NAFDigit = buffer.readf64(NAFForm, (NAFIndex - 1) * 8)

		if NAFDigit == 0 then
			buffer.copy(DoubleX, 0, ResultPoint, 0, CoordSize)
			buffer.copy(DoubleY, 0, ResultPoint, CoordSize, CoordSize)
			buffer.copy(DoubleZ, 0, ResultPoint, 2 * CoordSize, CoordSize)

			Square(DoubleX, DoubleA)
			Square(DoubleY, DoubleB)
			Square(DoubleZ, DoubleZ)
			FAdd(DoubleZ, DoubleZ, DoubleZ)
			FAdd(DoubleA, DoubleB, DoubleE)
			FAdd(DoubleX, DoubleY, DoubleX)
			Square(DoubleX, DoubleG)
			FSub(DoubleG, DoubleE, DoubleG)
			Carry(DoubleG, DoubleG)
			FSub(DoubleB, DoubleA, DoubleB)
			FSub(DoubleZ, DoubleB, DoubleZ)
			Carry(DoubleZ, DoubleZ)

			FMul(DoubleG, DoubleZ, DoubleX)
			FMul(DoubleB, DoubleE, DoubleY)
			FMul(DoubleZ, DoubleB, DoubleZ)
			FMul(DoubleG, DoubleE, DoubleE)

			buffer.copy(ResultPoint, 0, DoubleX, 0, CoordSize)
			buffer.copy(ResultPoint, CoordSize, DoubleY, 0, CoordSize)
			buffer.copy(ResultPoint, 2 * CoordSize, DoubleZ, 0, CoordSize)
			buffer.copy(ResultPoint, 3 * CoordSize, DoubleE, 0, CoordSize)

		elseif NAFDigit > 0 then
			buffer.copy(NielsPoint, 0, MultipleTable, ((NAFDigit - 1) * PointSize), PointSize)

			buffer.copy(P1X, 0, ResultPoint, 0, CoordSize)
			buffer.copy(P1Y, 0, ResultPoint, CoordSize, CoordSize)
			buffer.copy(P1Z, 0, ResultPoint, 2 * CoordSize, CoordSize)
			buffer.copy(P1T, 0, ResultPoint, 3 * CoordSize, CoordSize)
			buffer.copy(N2P, 0, NielsPoint, 0, CoordSize)
			buffer.copy(N2M, 0, NielsPoint, CoordSize, CoordSize)
			buffer.copy(N2Z, 0, NielsPoint, 2 * CoordSize, CoordSize)
			buffer.copy(N2T, 0, NielsPoint, 3 * CoordSize, CoordSize)

			FSub(P1Y, P1X, TMP)
			FMul(TMP, N2M, TMP)
			FAdd(P1Y, P1X, P1X)
			FMul(P1X, N2P, P1X)
			FMul(P1T, N2T, P1T)
			FMul(P1Z, N2Z, P1Z)

			FSub(P1X, TMP, P1Y)
			FSub(P1Z, P1T, N2P)
			FAdd(P1Z, P1T, P1Z)
			FAdd(P1X, TMP, P1X)

			FMul(P1Y, N2P, TMP)
			FMul(P1Z, P1X, P1T)
			FMul(N2P, P1Z, P1Z)
			FMul(P1Y, P1X, P1X)

			buffer.copy(ResultPoint, 0, TMP, 0, CoordSize)
			buffer.copy(ResultPoint, CoordSize, P1T, 0, CoordSize)
			buffer.copy(ResultPoint, 2 * CoordSize, P1Z, 0, CoordSize)
			buffer.copy(ResultPoint, 3 * CoordSize, P1X, 0, CoordSize)

		else
			buffer.copy(NielsPoint, 0, MultipleTable, (((-NAFDigit) - 1) * PointSize), PointSize)

			buffer.copy(P1X, 0, ResultPoint, 0, CoordSize)
			buffer.copy(P1Y, 0, ResultPoint, CoordSize, CoordSize)
			buffer.copy(P1Z, 0, ResultPoint, 2 * CoordSize, CoordSize)
			buffer.copy(P1T, 0, ResultPoint, 3 * CoordSize, CoordSize)
			buffer.copy(N2P, 0, NielsPoint, 0, CoordSize)
			buffer.copy(N2M, 0, NielsPoint, CoordSize, CoordSize)
			buffer.copy(N2Z, 0, NielsPoint, 2 * CoordSize, CoordSize)
			buffer.copy(N2T, 0, NielsPoint, 3 * CoordSize, CoordSize)

			FSub(P1Y, P1X, TMP)
			FMul(TMP, N2P, TMP)
			FAdd(P1Y, P1X, P1X)
			FMul(P1X, N2M, P1X)
			FMul(P1T, N2T, P1T)
			FMul(P1Z, N2Z, P1Z)

			FSub(P1X, TMP, P1Y)
			FAdd(P1Z, P1T, N2P)
			FSub(P1Z, P1T, P1Z)
			FAdd(P1X, TMP, P1X)

			FMul(P1Y, N2P, TMP)
			FMul(P1Z, P1X, P1T)
			FMul(N2P, P1Z, P1Z)
			FMul(P1Y, P1X, P1X)

			buffer.copy(ResultPoint, 0, TMP, 0, CoordSize)
			buffer.copy(ResultPoint, CoordSize, P1T, 0, CoordSize)
			buffer.copy(ResultPoint, 2 * CoordSize, P1Z, 0, CoordSize)
			buffer.copy(ResultPoint, 3 * CoordSize, P1X, 0, CoordSize)
		end
	end

	local Output = buffer.create(PointSize)
	buffer.copy(Output, 0, ResultPoint, 0, PointSize)
	return Output
end
end
do
--!strict
-- Verification-only adapter for the pinned rbx-cryptography Ed25519 modules.
-- The dependency sources and MIT notice are embedded byte-exactly by the
-- WI038 candidate builder; no signing or randomness API is exposed here.


Ed25519 = {}

local function concatenate(...: buffer): buffer
	local values = { ... }
	local total = 0
	for _, value in values do total += buffer.len(value) end
	local result = buffer.create(total)
	local offset = 0
	for _, value in values do
		local length = buffer.len(value)
		buffer.copy(result, offset, value, 0, length)
		offset += length
	end
	return result
end

function Ed25519.verify(message: string, signature: string, publicKey: string, sha512: ((string) -> string)?): boolean
	if type(message) ~= "string" or type(signature) ~= "string" or type(publicKey) ~= "string"
		or #signature ~= 64 or #publicKey ~= 32 or type(sha512) ~= "function" then
		return false
	end
	local signatureBuffer = buffer.fromstring(signature)
	local publicBuffer = buffer.fromstring(publicKey)
	if bit32.band(buffer.readu8(signatureBuffer, 63), 0xe0) ~= 0 then return false end

	local commitment = buffer.create(32)
	buffer.copy(commitment, 0, signatureBuffer, 0, 32)
	local response = buffer.create(32)
	buffer.copy(response, 0, signatureBuffer, 32, 32)
	if not FieldQuadratic.IsValidScalar(response) then return false end

	local publicPoint = Edwards25519.Decode(publicBuffer)
	local commitmentPoint = Edwards25519.Decode(commitment)
	if publicPoint == nil or commitmentPoint == nil then return false end

	local challengeRaw = sha512(buffer.tostring(concatenate(commitment, publicBuffer, buffer.fromstring(message))))
	if type(challengeRaw) ~= "string" or #challengeRaw ~= 64 then return false end
	local challenge = FieldQuadratic.DecodeWide(buffer.fromstring(challengeRaw))
	local responseScalar = FieldQuadratic.Decode(response)
	local responseBits, responseBitCount = FieldQuadratic.Bits(responseScalar)
	local responsePoint = Edwards25519.MulG(responseBits, responseBitCount)
	local challengeBits, challengeBitCount = FieldQuadratic.Bits(challenge)
	local challengePoint = Edwards25519.Mul(publicPoint, challengeBits, challengeBitCount)
	local combined = Edwards25519.Add(commitmentPoint, Edwards25519.Niels(challengePoint))
	local difference = Edwards25519.Sub(combined, Edwards25519.Niels(responsePoint))
	difference = Edwards25519.Double(difference)
	difference = Edwards25519.Double(difference)
	difference = Edwards25519.Double(difference)

	local x = buffer.create(104)
	local t = buffer.create(104)
	buffer.copy(x, 0, difference, 0, 104)
	buffer.copy(t, 0, difference, 3 * 104, 104)
	return FieldPrime.Eqz(x) and FieldPrime.Eqz(t)
end
end
local moduleFactories = {}
moduleFactories["public/key_store"] = function(__infinity_public_require)
local require = __infinity_public_require
--!strict
-- Optional, observable key persistence for executor filesystems.
-- Only the normalized key bytes are ever written to the stable file.

local KeyStore = {}
KeyStore.__index = KeyStore

local FOLDER = "InfinityPlatform"
local PATH = "InfinityPlatform/loader.key"
local MAX_KEY_BYTES = 512

local function normalizeKey(value: any): (string?, string?)
	if type(value) ~= "string" then
		return nil, "KEY_REQUIRED"
	end
	local key = string.match(value, "^%s*(.-)%s*$") or ""
	if #key == 0 then
		return nil, "KEY_REQUIRED"
	end
	if #key > MAX_KEY_BYTES or string.find(key, "[%z\1-\31\127]") ~= nil then
		return nil, "KEY_INVALID_LOCAL"
	end
	return key, nil
end

local function optionalFunction(environment: any, name: string): any
	if type(environment) ~= "table" then
		return nil
	end
	local value = environment[name]
	if type(value) == "function" then
		return value
	end
	return nil
end

function KeyStore.new(environment: any)
	local functions = {
		isfile = optionalFunction(environment, "isfile"),
		readfile = optionalFunction(environment, "readfile"),
		writefile = optionalFunction(environment, "writefile"),
		makefolder = optionalFunction(environment, "makefolder"),
		delfile = optionalFunction(environment, "delfile"),
	}
	local persistent = functions.isfile ~= nil
		and functions.readfile ~= nil
		and functions.writefile ~= nil
		and functions.makefolder ~= nil
	return setmetatable({
		functions = functions,
		persistent = persistent,
		failure = if persistent then nil else "FILESYSTEM_UNAVAILABLE",
	}, KeyStore)
end

function KeyStore.Normalize(value: any): (string?, string?)
	return normalizeKey(value)
end

function KeyStore:Path(): string
	return PATH
end

function KeyStore:IsPersistent(): boolean
	return self.persistent == true
end

function KeyStore:Failure(): string?
	return self.failure
end

function KeyStore:_degrade(code: string)
	self.persistent = false
	self.failure = code
end

function KeyStore:_eraseUnconfirmedWrite()
	if self.functions.delfile ~= nil then
		pcall(self.functions.delfile, PATH)
	elseif self.functions.writefile ~= nil then
		pcall(self.functions.writefile, PATH, "")
	end
end

function KeyStore:Read(): (string?, string)
	if not self:IsPersistent() then
		return nil, "unavailable"
	end
	local existsOk, exists = pcall(self.functions.isfile, PATH)
	if not existsOk then
		self:_degrade("FILESYSTEM_READ_FAILED")
		return nil, "unavailable"
	end
	if exists ~= true then
		return nil, "missing"
	end
	local readOk, raw = pcall(self.functions.readfile, PATH)
	if not readOk or type(raw) ~= "string" then
		self:_degrade("FILESYSTEM_READ_FAILED")
		return nil, "unavailable"
	end
	if raw == "" then
		return nil, "missing"
	end
	local key = normalizeKey(raw)
	if key == nil or key ~= raw then
		return nil, "invalid"
	end
	return key, "stored"
end

function KeyStore:Save(value: any): (boolean, string?)
	local key, keyError = normalizeKey(value)
	if key == nil then
		return false, keyError
	end
	if not self:IsPersistent() then
		return false, self.failure or "FILESYSTEM_UNAVAILABLE"
	end
	-- Existing folders commonly make makefolder throw. The following verified
	-- write is authoritative and keeps that executor difference harmless.
	pcall(self.functions.makefolder, FOLDER)
	local writeOk = pcall(self.functions.writefile, PATH, key)
	if not writeOk then
		self:_eraseUnconfirmedWrite()
		self:_degrade("FILESYSTEM_WRITE_FAILED")
		return false, self.failure
	end
	local existsOk, exists = pcall(self.functions.isfile, PATH)
	local readOk, written = pcall(self.functions.readfile, PATH)
	if not existsOk or exists ~= true or not readOk or written ~= key then
		self:_eraseUnconfirmedWrite()
		self:_degrade("FILESYSTEM_WRITE_FAILED")
		return false, self.failure
	end
	return true, nil
end

function KeyStore:Clear(): (boolean, string?)
	if not self:IsPersistent() then
		return false, self.failure or "FILESYSTEM_UNAVAILABLE"
	end
	local existsOk, exists = pcall(self.functions.isfile, PATH)
	if not existsOk then
		self:_degrade("FILESYSTEM_DELETE_FAILED")
		return false, self.failure
	end
	if exists ~= true then
		return true, nil
	end
	local deleteOk = false
	if self.functions.delfile ~= nil then
		deleteOk = pcall(self.functions.delfile, PATH)
	else
		deleteOk = pcall(self.functions.writefile, PATH, "")
	end
	if not deleteOk then
		self:_degrade("FILESYSTEM_DELETE_FAILED")
		return false, self.failure
	end
	local verifyOk, stillExists = pcall(self.functions.isfile, PATH)
	if not verifyOk then
		self:_degrade("FILESYSTEM_DELETE_FAILED")
		return false, self.failure
	end
	if stillExists == true then
		local readOk, raw = pcall(self.functions.readfile, PATH)
		if not readOk or raw ~= "" then
			self:_degrade("FILESYSTEM_DELETE_FAILED")
			return false, self.failure
		end
	end
	return true, nil
end

return KeyStore
end
moduleFactories["public/roblox_ui"] = function(__infinity_public_require)
local require = __infinity_public_require
--!nocheck
-- Compact Roblox shell for the public loader. The ScreenGui is only a host;
-- the visible Frame is fixed-size, touch-friendly, draggable and minimizable.

local RobloxUI = {}
RobloxUI.__index = RobloxUI

local COLORS = {
	background = Color3.fromRGB(15, 18, 26),
	panel = Color3.fromRGB(24, 29, 40),
	accent = Color3.fromRGB(245, 197, 66),
	text = Color3.fromRGB(240, 243, 249),
	muted = Color3.fromRGB(159, 169, 188),
	error = Color3.fromRGB(255, 113, 113),
	warning = Color3.fromRGB(255, 194, 92),
	success = Color3.fromRGB(102, 220, 157),
	ready = Color3.fromRGB(148, 187, 255),
}

local function create(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function round(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function resolveParent(options)
	if options and options.parent ~= nil then
		return options.parent
	end
	local players = game:GetService("Players")
	local player = players.LocalPlayer
	if player == nil then
		return nil
	end
	return player:FindFirstChildOfClass("PlayerGui")
end

function RobloxUI.new(options)
	local parent = resolveParent(options)
	if parent == nil then
		error("UI_UNAVAILABLE", 0)
	end
	local previous = parent:FindFirstChild("InfinityPlatformLoader")
	if previous ~= nil then
		pcall(function()
			previous:Destroy()
		end)
	end

	local screen = create("ScreenGui", {
		Name = "InfinityPlatformLoader",
		ResetOnSpawn = false,
		DisplayOrder = 1000000,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, parent)

	local frame = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(346, 286),
		BackgroundColor3 = COLORS.background,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
	}, screen)
	round(frame, 12)
	create("UIStroke", { Color = Color3.fromRGB(58, 67, 88), Thickness = 1 }, frame)

	local titleBar = create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = COLORS.panel,
		BorderSizePixel = 0,
		Active = true,
	}, frame)
	create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -62, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "Infinity Platform",
		TextColor3 = COLORS.text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, titleBar)
	local minimize = create("TextButton", {
		Name = "Minimize",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(38, 34),
		BackgroundColor3 = Color3.fromRGB(39, 46, 61),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "−",
		TextColor3 = COLORS.text,
		TextSize = 19,
		AutoButtonColor = true,
	}, titleBar)
	round(minimize, 8)

	local content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(12, 54),
		Size = UDim2.new(1, -24, 1, -66),
		BackgroundTransparency = 1,
	}, frame)
	local keyBox = create("TextBox", {
		Name = "KeyInput",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = COLORS.panel,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
		PlaceholderText = "Introduce tu key",
		PlaceholderColor3 = COLORS.muted,
		Text = "",
		TextColor3 = COLORS.text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, content)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, keyBox)
	round(keyBox, 8)

	local remember = create("TextButton", {
		Name = "Remember",
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "○ Recordar key",
		TextColor3 = COLORS.muted,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
	}, content)

	local submit = create("TextButton", {
		Name = "Submit",
		Position = UDim2.fromOffset(0, 86),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = COLORS.accent,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "Validar y cargar",
		TextColor3 = Color3.fromRGB(26, 23, 14),
		TextSize = 14,
		AutoButtonColor = true,
	}, content)
	round(submit, 8)

	local statusLabel = create("TextLabel", {
		Name = "Status",
		Position = UDim2.fromOffset(0, 134),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = "Preparando loader...",
		TextColor3 = COLORS.ready,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, content)

	local replaceButton = create("TextButton", {
		Name = "ReplaceKey",
		Position = UDim2.new(0, 0, 0, 178),
		Size = UDim2.new(0.5, -4, 0, 34),
		BackgroundColor3 = Color3.fromRGB(42, 51, 69),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Text = "Reemplazar",
		TextColor3 = COLORS.text,
		TextSize = 12,
		Visible = false,
	}, content)
	round(replaceButton, 8)
	local deleteButton = create("TextButton", {
		Name = "DeleteKey",
		Position = UDim2.new(0.5, 4, 0, 178),
		Size = UDim2.new(0.5, -4, 0, 34),
		BackgroundColor3 = Color3.fromRGB(67, 40, 47),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Text = "Borrar recordada",
		TextColor3 = COLORS.text,
		TextSize = 12,
		Visible = false,
	}, content)
	round(deleteButton, 8)

	local persistence = create("TextLabel", {
		Name = "PersistenceNotice",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = "",
		TextColor3 = COLORS.muted,
		TextSize = 10,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, content)

	local self = setmetatable({
		screen = screen,
		frame = frame,
		content = content,
		keyBox = keyBox,
		rememberButton = remember,
		submitButton = submit,
		statusLabel = statusLabel,
		replaceButton = replaceButton,
		deleteButton = deleteButton,
		persistenceLabel = persistence,
		remember = false,
		minimized = false,
		busy = false,
		connections = {},
	}, RobloxUI)

	local function connect(signal, callback)
		local connection = signal:Connect(callback)
		table.insert(self.connections, connection)
		return connection
	end

	connect(remember.Activated, function()
		if not self.busy then
			self:SetRemember(not self.remember)
		end
	end)
	connect(submit.Activated, function()
		if self.busy or type(self.submitHandler) ~= "function" then
			return
		end
		local key = keyBox.Text
		keyBox.Text = ""
		self.submitHandler(key, self.remember)
		key = nil
	end)
	connect(keyBox.FocusLost, function(enterPressed)
		if enterPressed and not self.busy and type(self.submitHandler) == "function" then
			local key = keyBox.Text
			keyBox.Text = ""
			self.submitHandler(key, self.remember)
			key = nil
		end
	end)
	connect(replaceButton.Activated, function()
		if not self.busy and type(self.replaceHandler) == "function" then
			self.replaceHandler()
		end
	end)
	connect(deleteButton.Activated, function()
		if not self.busy and type(self.deleteHandler) == "function" then
			self.deleteHandler()
		end
	end)
	connect(minimize.Activated, function()
		self.minimized = not self.minimized
		content.Visible = not self.minimized
		frame.Size = if self.minimized then UDim2.fromOffset(346, 44) else UDim2.fromOffset(346, 286)
		minimize.Text = if self.minimized then "+" else "−"
	end)

	local userInput = game:GetService("UserInputService")
	local dragging = false
	local dragStart = nil
	local startPosition = nil
	connect(titleBar.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = frame.Position
		end
	end)
	connect(titleBar.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	connect(userInput.InputChanged, function(input)
		if dragging and dragStart ~= nil and startPosition ~= nil
			and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		end
	end)

	return self
end

function RobloxUI:BindSubmit(callback)
	self.submitHandler = callback
end

function RobloxUI:BindReplace(callback)
	self.replaceHandler = callback
end

function RobloxUI:BindDelete(callback)
	self.deleteHandler = callback
end

function RobloxUI:Defer(callback)
	task.defer(callback)
end

function RobloxUI:SetKey(value)
	self.keyBox.Text = if type(value) == "string" then value else ""
end

function RobloxUI:SetRemember(value)
	self.remember = value == true
	self.rememberButton.Text = if self.remember then "● Recordar key" else "○ Recordar key"
	self.rememberButton.TextColor3 = if self.remember then COLORS.accent else COLORS.muted
end

function RobloxUI:SetPersistence(available, path)
	if available then
		self.persistenceLabel.Text = "Solo la key se guarda en " .. tostring(path) .. " (archivo observable/no seguro)."
	else
		self.persistenceLabel.Text = "Modo no persistente: la key se olvida al cerrar."
		self:SetRemember(false)
	end
end

function RobloxUI:SetStatus(kind, message)
	local color = COLORS[kind] or COLORS.ready
	self.statusLabel.TextColor3 = color
	self.statusLabel.Text = tostring(message)
end

function RobloxUI:SetRecovery(visible)
	self.replaceButton.Visible = visible == true
	self.deleteButton.Visible = visible == true
end

function RobloxUI:SetSubmitMode(mode)
	self.submitButton.Text = if mode == "save_next" then "Guardar para proxima carga" else "Validar y cargar"
end

function RobloxUI:SetBusy(value)
	self.busy = value == true
	self.submitButton.Active = not self.busy
	self.submitButton.AutoButtonColor = not self.busy
	self.submitButton.BackgroundTransparency = if self.busy then 0.45 else 0
	self.keyBox.TextEditable = not self.busy
	if self.busy then
		self.submitButton.Text = "Procesando..."
	elseif self.submitButton.Text == "Procesando..." then
		self.submitButton.Text = "Validar y cargar"
	end
end

function RobloxUI:Destroy()
	for _, connection in ipairs(self.connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	self.connections = {}
	self.keyBox.Text = ""
	pcall(function()
		self.screen:Destroy()
	end)
end

return RobloxUI
end
moduleFactories["public/universal_loader_app"] = function(__infinity_public_require)
local require = __infinity_public_require
--!nocheck
-- Build source for the one-shot universal authorization UI and key lifecycle.

local KeyStore = require("./key_store")
local Request = require("./universal_request_v3")

local App = {}
App.__index = App

local function safeCall(target, method, ...)
	local callback = target[method]
	if type(callback) == "function" then
		pcall(callback, target, ...)
	end
end

local function safeFailure(value)
	local text = tostring(value)
	if string.find(text, "LICENSE_NOT_AUTHORIZED", 1, true) ~= nil then
		return "LICENSE_NOT_AUTHORIZED"
	end
	if string.find(text, "CAPABILITY_UNAVAILABLE", 1, true) ~= nil then
		return "CAPABILITY_UNAVAILABLE"
	end
	return "AUTHORIZATION_FAILED"
end

function App.new(config)
	if type(config) ~= "table"
		or type(config.ui) ~= "table"
		or type(config.profile) ~= "table"
		or type(config.provider) ~= "table"
		or type(config.placeIdProvider) ~= "function" then
		error("LOADER_CONFIGURATION_INVALID", 0)
	end
	local app = setmetatable({
		ui = config.ui,
		profile = config.profile,
		provider = config.provider,
		placeIdProvider = config.placeIdProvider,
		keyStore = config.keyStore or KeyStore.new(config.environment),
		attempted = false,
		busy = false,
		replacement = false,
		destroyed = false,
	}, App)
	safeCall(app.ui, "BindSubmit", function(key, remember)
		app:_submit(key, remember)
	end)
	safeCall(app.ui, "BindReplace", function()
		app:_replaceStoredKey()
	end)
	safeCall(app.ui, "BindDelete", function()
		app:_deleteStoredKey()
	end)
	return app
end

function App:_setBusy(value)
	self.busy = value == true
	safeCall(self.ui, "SetBusy", self.busy)
end

function App:_persistenceNotice()
	safeCall(self.ui, "SetPersistence", self.keyStore:IsPersistent(), self.keyStore:Path())
end

function App:Start()
	if self.destroyed then
		return
	end
	self:_persistenceNotice()
	local storedKey, readState = self.keyStore:Read()
	self:_persistenceNotice()
	if readState == "invalid" then
		safeCall(self.ui, "SetRecovery", true)
		safeCall(self.ui, "SetStatus", "error", "El archivo de key no es valido. Borralo o reemplazalo explicitamente.")
		return
	end
	if storedKey ~= nil then
		safeCall(self.ui, "SetKey", storedKey)
		safeCall(self.ui, "SetRemember", true)
		safeCall(self.ui, "SetStatus", "ready", "Key recordada encontrada. Se validara una sola vez.")
		local function validateStored()
			self:_submit(storedKey, true, true)
			storedKey = nil
		end
		if type(self.ui.Defer) == "function" then
			self.ui:Defer(validateStored)
		else
			validateStored()
		end
		return
	end
	if self.keyStore:IsPersistent() then
		safeCall(self.ui, "SetStatus", "ready", "Introduce tu key. Puedes recordarla en este dispositivo observable.")
	else
		safeCall(self.ui, "SetStatus", "warning", "Introduce tu key. El filesystem no esta disponible; no se guardara.")
	end
end

function App:_saveForNextLoad(key, remember)
	if not remember then
		safeCall(self.ui, "SetStatus", "warning", "Esta ejecucion ya uso su intento. Recarga para introducir otra key.")
		return
	end
	local saved = self.keyStore:Save(key)
	self:_persistenceNotice()
	safeCall(self.ui, "SetKey", "")
	if saved then
		safeCall(self.ui, "SetStatus", "success", "Key reemplazada. Ejecuta el loader de nuevo para validarla.")
	else
		safeCall(self.ui, "SetStatus", "warning", "No se pudo guardar. Recarga e introduce la key manualmente.")
	end
end

function App:_submit(rawKey, remember, fromStored)
	if self.destroyed or self.busy then
		return
	end
	local key, keyError = KeyStore.Normalize(rawKey)
	rawKey = nil
	if key == nil then
		safeCall(self.ui, "SetStatus", "error", if keyError == "KEY_REQUIRED" then "Introduce una key." else "La key contiene caracteres no admitidos.")
		return
	end
	local shouldRemember = remember == true
	local persistenceKey = if shouldRemember and fromStored ~= true then key else nil
	if self.attempted then
		if self.replacement then
			self:_saveForNextLoad(key, shouldRemember)
		else
			safeCall(self.ui, "SetStatus", "warning", "Esta ejecucion ya uso su intento. Recarga para otro intento.")
		end
		key = nil
		persistenceKey = nil
		return
	end
	if self.profile.operational ~= true then
		self.attempted = true
		key = nil
		persistenceKey = nil
		safeCall(self.ui, "SetKey", "")
		safeCall(self.ui, "SetStatus", "warning", "El perfil beta universal aun no esta habilitado.")
		return
	end
	if type(self.provider.newIdentity) ~= "function"
		or type(self.provider.encodeCanonicalJSON) ~= "function"
		or type(self.provider.executeOnce) ~= "function" then
		key = nil
		persistenceKey = nil
		safeCall(self.ui, "SetStatus", "error", "La configuracion publica del loader es incompleta.")
		return
	end
	local identityOk, identity = pcall(self.provider.newIdentity)
	local requestOk, request, idempotencyKey = pcall(Request.Build, key, tostring(self.placeIdProvider()), identity)
	key = nil
	safeCall(self.ui, "SetKey", "")
	if not identityOk or not requestOk or type(idempotencyKey) ~= "string" then
		persistenceKey = nil
		safeCall(self.ui, "SetStatus", "error", "No se pudo preparar la autorizacion de forma segura.")
		return
	end
	local encodedOk, requestBytes = pcall(self.provider.encodeCanonicalJSON, request)
	if not encodedOk or type(requestBytes) ~= "string" then
		persistenceKey = nil
		safeCall(self.ui, "SetStatus", "error", "No se pudo preparar la autorizacion de forma segura.")
		return
	end
	request.license_key = nil
	request = nil
	self.attempted = true
	self:_setBusy(true)
	local executed, result = pcall(self.provider.executeOnce, requestBytes, idempotencyKey)
	requestBytes = ""
	idempotencyKey = ""
	self:_setBusy(false)
	if executed and type(result) == "table" and result.ok == true then
		if shouldRemember and fromStored ~= true then
			local persisted = self.keyStore:Save(persistenceKey)
			persistenceKey = nil
			self:_persistenceNotice()
			if not persisted then
				safeCall(self.ui, "SetStatus", "success", "Carga completada. La key no pudo guardarse y se olvido.")
			else
				safeCall(self.ui, "SetStatus", "success", "Carga completada. La key quedo recordada como archivo observable.")
			end
		else
			persistenceKey = nil
			safeCall(self.ui, "SetStatus", "success", "Carga completada.")
		end
		return result
	end
	persistenceKey = nil
	local code = safeFailure(if executed then result else "AUTHORIZATION_FAILED")
	if code == "LICENSE_NOT_AUTHORIZED" then
		safeCall(self.ui, "SetRecovery", true)
		safeCall(self.ui, "SetStatus", "error", "No fue posible autorizar la carga. No se descargo contenido.")
	else
		safeCall(self.ui, "SetStatus", "error", "La carga fallo de forma segura (" .. code .. "). Recarga para intentarlo de nuevo.")
	end
	return nil
end

function App:_replaceStoredKey()
	if self.destroyed or self.busy then
		return
	end
	self.keyStore:Clear()
	self.replacement = true
	self:_persistenceNotice()
	safeCall(self.ui, "SetKey", "")
	safeCall(self.ui, "SetRemember", self.keyStore:IsPersistent())
	safeCall(self.ui, "SetRecovery", false)
	safeCall(self.ui, "SetSubmitMode", if self.attempted then "save_next" else "validate")
	if self.attempted then
		safeCall(self.ui, "SetStatus", "ready", "Introduce la nueva key y guardala para la proxima ejecucion.")
	else
		safeCall(self.ui, "SetStatus", "ready", "Introduce la nueva key.")
	end
end

function App:_deleteStoredKey()
	if self.destroyed or self.busy then
		return
	end
	local cleared = self.keyStore:Clear()
	self:_persistenceNotice()
	safeCall(self.ui, "SetKey", "")
	safeCall(self.ui, "SetRecovery", false)
	if cleared then
		safeCall(self.ui, "SetStatus", "success", if self.attempted then "Key borrada. Recarga para una validacion nueva." else "Key borrada. Introduce otra cuando quieras.")
	else
		safeCall(self.ui, "SetStatus", "warning", "No hay almacenamiento persistente que borrar.")
	end
end

function App:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	safeCall(self.ui, "SetKey", "")
	safeCall(self.ui, "Destroy")
end

return App
end
moduleFactories["public/universal_request_v3"] = function(__infinity_public_require)
local require = __infinity_public_require
--!strict
-- Build source for the closed universal-placeid-catalog/v1-beta request.

local Request = {}

local CAPABILITIES = {
	"crypto.sha256.v1",
	"crypto.signature.verify.v1",
	"runtime.luau.loadstring",
	"time.utc.rfc3339.v1",
	"transport.https-post-headers-json.v1",
	"transport.response-bounded-bytes.v1",
}

local IDENTITY_FIELDS = {
	load_id = true,
	instance_nonce = true,
	configured_user_id = true,
	installation_pseudonym = true,
	idempotency_key = true,
}

local function canonicalPlaceId(value: any): string
	if type(value) ~= "string" or #value < 1 or #value > 20 then
		error("RUNTIME_CONTEXT_INVALID", 0)
	end
	if string.match(value, "^[1-9][0-9]*$") == nil then
		error("RUNTIME_CONTEXT_INVALID", 0)
	end
	return value
end

local function validLoadId(value: any): boolean
	if type(value) ~= "string" or #value ~= 36 then
		return false
	end
	return string.sub(value, 9, 9) == "-"
		and string.sub(value, 14, 14) == "-"
		and string.sub(value, 19, 19) == "-"
		and string.sub(value, 24, 24) == "-"
		and string.match(string.gsub(value, "-", ""), "^%x+$") ~= nil
end

local function validNonce(value: any): boolean
	return type(value) == "string"
		and #value >= 22
		and #value <= 128
		and string.match(value, "^[A-Za-z0-9_-]+$") ~= nil
end

local function validPseudonym(value: any): boolean
	if value == nil then
		return true
	end
	return type(value) == "string"
		and #value >= 14
		and #value <= 134
		and string.match(value, "^instp_[A-Za-z0-9_-]+$") ~= nil
end

local function validateIdentity(identity: any)
	if type(identity) ~= "table" then
		error("LOAD_IDENTITY_INVALID", 0)
	end
	for key, _ in pairs(identity) do
		if IDENTITY_FIELDS[key] ~= true then
			error("LOAD_IDENTITY_INVALID", 0)
		end
	end
	if not validLoadId(identity.load_id)
		or not validNonce(identity.instance_nonce)
		or type(identity.configured_user_id) ~= "string"
		or #identity.configured_user_id < 1
		or #identity.configured_user_id > 128
		or not validPseudonym(identity.installation_pseudonym)
		or type(identity.idempotency_key) ~= "string"
		or #identity.idempotency_key < 16
		or #identity.idempotency_key > 160 then
		error("LOAD_IDENTITY_INVALID", 0)
	end
end

function Request.Build(licenseKey: any, placeId: any, identity: any): (any, string)
	if type(licenseKey) ~= "string" or #licenseKey < 1 or #licenseKey > 160 then
		error("KEY_INVALID_LOCAL", 0)
	end
	validateIdentity(identity)
	local request = {
		schema = "load-authorization-request/v3-beta",
		load_id = identity.load_id,
		instance_nonce = identity.instance_nonce,
		license_key = licenseKey,
		subject = {
			configured_user_id = identity.configured_user_id,
			installation_pseudonym = identity.installation_pseudonym,
		},
		runtime_context = {
			place_id = canonicalPlaceId(placeId),
		},
		client = {
			loader_version = "0.3.0",
			supported_contracts = {
				authorization_response = { "v2-draft" },
				private_payload_delivery = { "v1-draft" },
				distribution_manifest = { 2 },
			},
			capability_profile = CAPABILITIES,
		},
	}
	return request, identity.idempotency_key
end

return Request
end
moduleFactories["public/universal_roblox_bootstrap"] = function(__infinity_public_require)
local require = __infinity_public_require
--!nocheck
-- Build source for the Roblox/Delta shell with passive capability discovery.

local App = require("./universal_loader_app")
local RobloxUI = require("./roblox_ui")

local Bootstrap = {}

local FILESYSTEM_NAMES = { "isfile", "readfile", "writefile", "makefolder", "delfile" }
local SINGLETON_KEY = "__INFINITY_PLATFORM_UNIVERSAL_LOADER_V3"

local function currentEnvironment()
	local candidates = {}
	local base = _G
	if type(getfenv) == "function" then
		local ok, value = pcall(getfenv, 0)
		if ok and type(value) == "table" then
			base = value
		end
	end
	table.insert(candidates, base)
	local getGlobalEnvironment = rawget(base, "getgenv")
	if type(getGlobalEnvironment) == "function" then
		local ok, value = pcall(getGlobalEnvironment)
		if ok and type(value) == "table" then
			table.insert(candidates, 1, value)
		end
	end
	local result = {}
	for _, name in ipairs(FILESYSTEM_NAMES) do
		for _, candidate in ipairs(candidates) do
			local value = rawget(candidate, name)
			if type(value) == "function" then
				result[name] = value
				break
			end
		end
	end
	result.__state = candidates[1]
	return result
end

local function copiedConfig(config)
	local result = {}
	for key, value in pairs(config) do
		result[key] = value
	end
	return result
end

function Bootstrap.start(publicConfig)
	if type(publicConfig) ~= "table" then
		error("LOADER_CONFIGURATION_INVALID", 0)
	end
	local ui = RobloxUI.new({ parent = publicConfig.ui_parent })
	local environment = publicConfig.environment or currentEnvironment()
	local stateEnvironment = environment.__state
	if type(stateEnvironment) ~= "table" then
		stateEnvironment = _G
	end
	local previous = rawget(stateEnvironment, SINGLETON_KEY)
	if type(previous) == "table" and type(previous.Destroy) == "function" then
		pcall(previous.Destroy, previous)
	end
	local config = copiedConfig(publicConfig)
	config.ui = ui
	config.environment = environment
	config.placeIdProvider = function()
		return game.PlaceId
	end
	local ok, app = pcall(App.new, config)
	if not ok then
		ui:SetStatus("error", "La configuracion publica del loader es incompleta.")
		return nil
	end
	rawset(stateEnvironment, SINGLETON_KEY, app)
	local started = pcall(app.Start, app)
	if not started then
		ui:SetStatus("error", "El loader fallo de forma segura antes de autorizar.")
	end
	return app
end

return Bootstrap
end
moduleFactories["public/adapter_runtime"] = function(__infinity_public_require)
local require = __infinity_public_require
--!strict
-- Closed module resolver and game-adapter/v1 lifecycle. Compilation creates
-- inert factories for every module; Start executes only the delivered
-- entrypoint and the dependencies it explicitly requests.

local AdapterRuntime = {}
AdapterRuntime.__index = AdapterRuntime

local ADAPTER_SOURCE_COMPONENT = "game.adapter"

local function fail(code: string): never
	error(code, 0)
end

local function parseVersion(value: any): {number}?
	if type(value) ~= "string" then
		return nil
	end
	local major, minor, patch = string.match(value, "^(%d+)%.(%d+)%.(%d+)$")
	if major == nil then
		return nil
	end
	return { tonumber(major) :: number, tonumber(minor) :: number, tonumber(patch) :: number }
end

local function compareVersion(left: {number}, right: {number}): number
	for index = 1, 3 do
		if left[index] < right[index] then
			return -1
		elseif left[index] > right[index] then
			return 1
		end
	end
	return 0
end

local function containsId(values: any, expected: any): boolean
	if type(values) ~= "table" then
		return false
	end
	for _, value in ipairs(values) do
		if tostring(value) == tostring(expected) then
			return true
		end
	end
	return false
end

local function resultOk(value: any): boolean
	return value == nil or value == true or (type(value) == "table" and value.ok == true)
end

local function isPrintableBuildId(value: any): boolean
	if type(value) ~= "string" or #value < 4 or #value > 160 then
		return false
	end
	for index = 1, #value do
		local byte = string.byte(value, index)
		if byte == nil or byte < 32 or byte > 126 then
			return false
		end
	end
	return true
end

local function isHexRef(value: any): boolean
	return type(value) == "string" and #value == 40 and string.match(value, "^[a-f0-9]+$") ~= nil
end

local function isRepositoryId(value: any): boolean
	return type(value) == "string" and #value >= 9 and #value <= 101
		and string.match(value, "^repo_[A-Za-z0-9._%-]+$") ~= nil
end

local function selectAdapterSource(distributionManifest: any, authorizedProductId: any): any
	if type(distributionManifest) ~= "table" or type(authorizedProductId) ~= "string"
		or distributionManifest.product_id ~= authorizedProductId then
		fail("ADAPTER_MANIFEST_MISMATCH")
	end
	local artifact = distributionManifest.artifact
	local source = distributionManifest.source
	local inputs = if type(source) == "table" then source.inputs else nil
	if type(artifact) ~= "table" or type(artifact.component_version) ~= "string"
		or type(artifact.build_id) ~= "string" or type(inputs) ~= "table"
		or #inputs < 1 or #inputs > 32 then
		fail("ADAPTER_MANIFEST_MISMATCH")
	end

	local selected: any = nil
	for _, rawInput in ipairs(inputs) do
		local input: any = rawInput
		if type(input) == "table" and input.component == ADAPTER_SOURCE_COMPONENT then
			if selected ~= nil then
				fail("ADAPTER_MANIFEST_MISMATCH")
			end
			selected = input
		end
	end
	if selected == nil or selected.component_version ~= artifact.component_version
		or not isPrintableBuildId(selected.component_build_id)
		or not isRepositoryId(selected.repository_id)
		or not isHexRef(selected.commit_sha) or not isHexRef(selected.tree_sha) then
		fail("ADAPTER_MANIFEST_MISMATCH")
	end
	return selected
end

function AdapterRuntime.SelectAdapterSource(distributionManifest: any, authorizedProductId: any): any
	return selectAdapterSource(distributionManifest, authorizedProductId)
end

function AdapterRuntime.new(options: any)
	if type(options) ~= "table" or type(options.loadstring) ~= "function"
		or type(options.expected) ~= "table" or type(options.platformContext) ~= "table"
		or type(options.distributionManifest) ~= "table" or type(options.adapterSource) ~= "table" then
		fail("ADAPTER_RUNTIME_CONFIGURATION_INVALID")
	end
	local adapterSource = AdapterRuntime.SelectAdapterSource(options.distributionManifest, options.expected.productId)
	if options.adapterSource ~= adapterSource then
		fail("ADAPTER_MANIFEST_MISMATCH")
	end
	return setmetatable({
		loadstring = options.loadstring,
		expected = options.expected,
		adapterSource = adapterSource,
		platformContext = options.platformContext,
	}, AdapterRuntime)
end

function AdapterRuntime:Compile(moduleId: string, source: string): any
	if type(moduleId) ~= "string" or type(source) ~= "string" then
		fail("ARTIFACT_COMPILE_FAILED")
	end
	-- The delivered source remains inert while all modules are compiled.
	local wrapper = "return function(__infinity_require)\nlocal require = __infinity_require\n" .. source .. "\nend"
	local chunk, _compileError = self.loadstring(wrapper, "@infinity-private/" .. moduleId)
	wrapper = ""
	if type(chunk) ~= "function" then
		_compileError = nil
		fail("ARTIFACT_COMPILE_FAILED")
	end
	local ok, factory = pcall(chunk)
	chunk = nil
	if not ok or type(factory) ~= "function" then
		factory = nil
		fail("ARTIFACT_COMPILE_FAILED")
	end
	return factory
end

function AdapterRuntime:_validateAdapter(adapter: any)
	if type(adapter) ~= "table" or adapter.contractVersion ~= "v1-draft"
		or type(adapter.manifest) ~= "table" or type(adapter.probe) ~= "function" or type(adapter.create) ~= "function" then
		fail("ADAPTER_CONTRACT_UNSUPPORTED")
	end
	local manifest = adapter.manifest
	local expected = self.expected
	local adapterSource = self.adapterSource
	if manifest.productId ~= expected.productId or manifest.adapterVersion ~= adapterSource.component_version
		or manifest.buildId ~= adapterSource.component_build_id then
		fail("ADAPTER_MANIFEST_MISMATCH")
	end
	local core = parseVersion(expected.coreVersion)
	local minimum = parseVersion(manifest.minimumCoreVersion)
	local maximum = parseVersion(manifest.maximumCoreVersionExclusive)
	if core == nil or minimum == nil or maximum == nil or compareVersion(core, minimum) < 0 or compareVersion(core, maximum) >= 0 then
		fail("ADAPTER_CONTRACT_UNSUPPORTED")
	end
	local targets = manifest.targets
	if type(targets) ~= "table" then
		fail("ADAPTER_TARGET_UNSUPPORTED")
	end
	local universeMatch = containsId(targets.universeIds, expected.universeId)
	local placeMatch = containsId(targets.placeIds, expected.placeId)
	if not universeMatch and not placeMatch then
		fail("ADAPTER_TARGET_UNSUPPORTED")
	end
	local capabilities = self.platformContext.capabilities
	if type(capabilities) ~= "table" or type(capabilities.has) ~= "function" then
		fail("ADAPTER_CAPABILITY_MISSING")
	end
	for _, capabilityId in ipairs(manifest.requiredCapabilities or {}) do
		if capabilities:has(capabilityId) ~= true then
			fail("ADAPTER_CAPABILITY_MISSING")
		end
	end
end

function AdapterRuntime:Start(entrypoint: string, compiled: any): () -> ()
	if type(entrypoint) ~= "string" or type(compiled) ~= "table" or type(compiled[entrypoint]) ~= "function" then
		fail("ARTIFACT_ENTRYPOINT_INVALID")
	end
	local cache = {}
	local loading = {}
	local function closedRequire(moduleId: string): any
		if cache[moduleId] ~= nil then
			return cache[moduleId]
		end
		local factory = compiled[moduleId]
		if type(factory) ~= "function" or loading[moduleId] then
			fail("ARTIFACT_ENTRYPOINT_INVALID")
		end
		loading[moduleId] = true
		local ok, exported = pcall(factory, closedRequire)
		loading[moduleId] = nil
		if not ok or exported == nil then
			fail("ARTIFACT_ENTRYPOINT_INVALID")
		end
		cache[moduleId] = exported
		return exported
	end

	local adapter = closedRequire(entrypoint)
	local valid, validationError = pcall(self._validateAdapter, self, adapter)
	if not valid then
		for key, _ in pairs(cache) do
			cache[key] = nil
		end
		for key, _ in pairs(compiled) do
			compiled[key] = nil
		end
		error(validationError, 0)
	end
	local probeOk, probe = pcall(adapter.probe, {
		universeId = self.expected.universeId,
		placeId = self.expected.placeId,
	})
	if not probeOk or type(probe) ~= "table" or probe.ok ~= true or probe.match ~= true then
		fail("ADAPTER_TARGET_UNSUPPORTED")
	end
	local createOk, instance = pcall(adapter.create, self.platformContext)
	if not createOk or type(instance) ~= "table" or type(instance.installUI) ~= "function"
		or type(instance.start) ~= "function" or type(instance.stop) ~= "function" or type(instance.unload) ~= "function" then
		fail("ARTIFACT_ENTRYPOINT_INVALID")
	end
	local cleaned = false
	local function cleanup()
		if cleaned then
			return
		end
		cleaned = true
		pcall(instance.stop, instance, "platform-loader-unload")
		pcall(instance.unload, instance, "platform-loader-unload")
		for key, _ in pairs(cache) do
			cache[key] = nil
		end
		for key, _ in pairs(compiled) do
			compiled[key] = nil
		end
	end
	local installed, installResult = pcall(instance.installUI, instance)
	if not installed or not resultOk(installResult) then
		cleanup()
		fail("ADAPTER_START_FAILED")
	end
	local started, startResult = pcall(instance.start, instance)
	if not started or not resultOk(startResult) then
		cleanup()
		fail("ADAPTER_START_FAILED")
	end
	return cleanup
end

return AdapterRuntime
end
moduleFactories["public/private_loader"] = function(__infinity_public_require)
local require = __infinity_public_require
--!strict
-- Neutral private loader orchestration for private-staging-set/1.
-- Cryptography, JCS, bounded transport, time and compilation are injected
-- capabilities. This file deliberately implements none of those primitives.

local AdapterRuntime = require("./adapter_runtime")

local Loader = {}
Loader.__index = Loader

local REQUIRED_CAPABILITIES = {
	"crypto.sha256.v1",
	"crypto.signature.verify.v1",
	"runtime.luau.loadstring",
	"time.utc.rfc3339.v1",
	"transport.https-post-headers-json.v1",
	"transport.response-bounded-bytes.v1",
}

local SAFE_MESSAGES = {
	TARGET_NOT_OPERATIONAL = "El perfil de ejecucion no esta habilitado.",
	CAPABILITY_UNAVAILABLE = "Faltan capacidades verificadas del entorno.",
	LICENSE_NOT_AUTHORIZED = "La key no es valida, ha caducado o no esta activa.",
	AUTHORIZATION_FAILED = "No se pudo autorizar esta carga.",
	MANIFEST_INVALID = "La release autorizada no supero la verificacion.",
	GRANT_INVALID = "La autorizacion privada no supero la verificacion.",
	DELIVERY_FAILED = "No se pudo entregar el artefacto autorizado.",
	BUNDLE_INVALID = "El artefacto autorizado no supero la verificacion.",
	ADAPTER_MANIFEST_MISMATCH = "El adapter entregado no coincide con su identidad firmada.",
	COMPILE_FAILED = "El artefacto no pudo compilarse de forma atomica.",
	START_FAILED = "El runtime no pudo iniciarse.",
}

local function fail(provider: any, code: string): never
	if type(provider.notify) == "function" then
		pcall(provider.notify, code, SAFE_MESSAGES[code] or SAFE_MESSAGES.AUTHORIZATION_FAILED)
	end
	error(code, 0)
end

local function status(provider: any, state: string, message: string)
	if type(provider.status) == "function" then
		pcall(provider.status, state, message)
	end
end

local function graphOrder(provider: any, modules: any, entrypoint: string): {string}
	if modules[entrypoint] == nil then
		fail(provider, "BUNDLE_INVALID")
	end
	local visiting = {}
	local visited = {}
	local ordered = {}
	local function walk(moduleId: string)
		if visiting[moduleId] then
			fail(provider, "BUNDLE_INVALID")
		end
		if visited[moduleId] then
			return
		end
		local module = modules[moduleId]
		if module == nil then
			fail(provider, "BUNDLE_INVALID")
		end
		visiting[moduleId] = true
		for _, dependency in module.dependencies do
			walk(dependency)
		end
		visiting[moduleId] = nil
		visited[moduleId] = true
		table.insert(ordered, moduleId)
	end
	walk(entrypoint)
	for moduleId, _ in modules do
		if not visited[moduleId] then
			fail(provider, "BUNDLE_INVALID")
		end
	end
	return ordered
end

function Loader.new(profile: any, capabilityProvider: any)
	return setmetatable({
		profile = profile,
		provider = capabilityProvider,
		state = "new",
		cleanup = {},
		used = false,
	}, Loader)
end

function Loader:_checkCapabilities()
	status(self.provider, "checking_capabilities", "Comprobando capacidades del entorno...")
	if self.profile.operational ~= true then
		fail(self.provider, "TARGET_NOT_OPERATIONAL")
	end
	for index, capabilityId in REQUIRED_CAPABILITIES do
		if self.profile.required_capabilities[index] ~= capabilityId then
			fail(self.provider, "CAPABILITY_UNAVAILABLE")
		end
		if self.provider.probe(capabilityId) ~= "verified" then
			fail(self.provider, "CAPABILITY_UNAVAILABLE")
		end
	end
	if #self.profile.required_capabilities ~= #REQUIRED_CAPABILITIES then
		fail(self.provider, "CAPABILITY_UNAVAILABLE")
	end
	self.state = "capabilities_checked"
end

function Loader:_authorize(requestBytes: string, idempotencyKey: string)
	status(self.provider, "authorizing", "Validando la key una vez para esta carga...")
	local retryCount = self.profile.authorization_transport_retry
	if retryCount ~= 0 and retryCount ~= 1 then
		fail(self.provider, "CAPABILITY_UNAVAILABLE")
	end
	local response = self.provider.authorize(requestBytes, idempotencyKey)
	if response.kind == "ambiguous_transport" and retryCount == 1 then
		-- Same immutable bytes and key: still one logical decision.
		response = self.provider.authorize(requestBytes, idempotencyKey)
	end
	if response.status == 403 then
		fail(self.provider, "LICENSE_NOT_AUTHORIZED")
	end
	if response.status ~= 201 then
		fail(self.provider, "AUTHORIZATION_FAILED")
	end
	return response
end

function Loader:_verifyBundle(bundleBytes: string, manifest: any)
	status(self.provider, "verifying_bundle", "Verificando tamano e integridad del adapter...")
	local artifact = manifest.artifact
	if type(bundleBytes) ~= "string" or #bundleBytes == 0 or #bundleBytes > 16777216 then
		fail(self.provider, "BUNDLE_INVALID")
	end
	if #bundleBytes ~= artifact.size_bytes or self.provider.sha256(bundleBytes) ~= artifact.sha256 then
		fail(self.provider, "BUNDLE_INVALID")
	end
	if artifact.artifact_id ~= "sha256:" .. artifact.sha256 then
		fail(self.provider, "BUNDLE_INVALID")
	end
	local bundle = self.provider.decodeCanonicalJSON(bundleBytes)
	if bundle.schema ~= "private-runtime-bundle/v1" or not self.provider.validateBundleEnvelope(bundle, artifact) then
		fail(self.provider, "BUNDLE_INVALID")
	end
	local modules = {}
	local index = {}
	local moduleCount = 0
	for _, item in ipairs(bundle.modules :: any) do
		moduleCount += 1
		if moduleCount > 128 or #item.dependencies > 32 then
			fail(self.provider, "BUNDLE_INVALID")
		end
		if modules[item.module_id] ~= nil then
			fail(self.provider, "BUNDLE_INVALID")
		end
		local source = self.provider.base64urlDecodeCanonical(item.source_base64url)
		if #source == 0 or #source > 1048576 or #source ~= item.source_size_bytes or self.provider.sha256(source) ~= item.source_sha256 then
			fail(self.provider, "BUNDLE_INVALID")
		end
		modules[item.module_id] = { dependencies = item.dependencies, source = source }
		table.insert(index, { module_id = item.module_id, source_sha256 = item.source_sha256 })
	end
	if moduleCount == 0 then
		fail(self.provider, "BUNDLE_INVALID")
	end
	if self.provider.sha256(self.provider.canonicalizeModuleIndex(index)) ~= artifact.module_index_sha256 then
		fail(self.provider, "BUNDLE_INVALID")
	end
	return modules, graphOrder(self.provider, modules, bundle.entrypoint_module), bundle.entrypoint_module
end

function Loader:_runCleanup()
	for index = #self.cleanup, 1, -1 do
		pcall(self.cleanup[index])
	end
	self.cleanup = {}
	if type(self.provider.cleanupEphemeral) == "function" then
		pcall(self.provider.cleanupEphemeral)
	end
end

function Loader:_load(requestBytes: string, idempotencyKey: string)
	self:_checkCapabilities() -- mandatory before authorize/network
	local request = self.provider.validateAuthorizationRequest(requestBytes, idempotencyKey)
	local response = self:_authorize(requestBytes, idempotencyKey)
	local authorization = self.provider.validateAuthorizationResponse(response, request)
	-- Parsed key material is no longer needed after the unique authorization.
	if type(request) == "table" then
		request.license_key = nil
	end
	requestBytes = ""
	status(self.provider, "authorized", "Carga autorizada. Verificando manifest...")
	local manifest = self.provider.verifyManifest(authorization.manifest, request)
	local grant = self.provider.verifyGrantAndExactScope(authorization.grant, manifest, request, authorization)
	status(self.provider, "redeeming", "Descargando el adapter autorizado...")
	-- There is intentionally no retry around redeem.
	local delivery = self.provider.redeemExactlyOnce(grant, authorization.request_id)
	if delivery.status ~= 200 then
		fail(self.provider, "DELIVERY_FAILED")
	end
	local modules, order, entrypoint = self:_verifyBundle(delivery.body, manifest)
	local sourceOk, adapterSource = pcall(AdapterRuntime.SelectAdapterSource, manifest, manifest.product_id)
	if not sourceOk then
		fail(self.provider, "ADAPTER_MANIFEST_MISMATCH")
	end
	status(self.provider, "compiling", "Compilando todos los modulos sin iniciar efectos...")
	local compiled: {[string]: any} = {}
	for _, moduleId in order do
		local ok, result = pcall(self.provider.compile, moduleId, modules[moduleId].source, manifest, adapterSource)
		if not ok or type(result) ~= "function" then
			compiled = {}
			fail(self.provider, "COMPILE_FAILED")
		end
		compiled[moduleId] = result
	end
	status(self.provider, "starting", "Iniciando solo el adapter entregado...")
	local ok, cleanup = pcall(self.provider.start, entrypoint, compiled, manifest, request, authorization, adapterSource)
	if not ok then
		if string.find(tostring(cleanup), "ADAPTER_MANIFEST_MISMATCH", 1, true) ~= nil then
			fail(self.provider, "ADAPTER_MANIFEST_MISMATCH")
		end
		fail(self.provider, "START_FAILED")
	end
	if cleanup ~= nil then
		if type(cleanup) ~= "function" then
			fail(self.provider, "START_FAILED")
		end
		table.insert(self.cleanup, cleanup)
	end
	self.state = "running"
	status(self.provider, "running", "Adapter cargado.")
	-- No timers, polling, heartbeat, refresh or revalidation are installed.
	return self
end

function Loader:Load(requestBytes: string, idempotencyKey: string)
	if self.used then
		fail(self.provider, "AUTHORIZATION_FAILED")
	end
	self.used = true
	local ok, result = pcall(function()
		return self:_load(requestBytes, idempotencyKey)
	end)
	if ok then
		return result
	end
	self:_runCleanup()
	self.state = "failed_closed"
	local code = tostring(result)
	if SAFE_MESSAGES[code] == nil then
		code = "AUTHORIZATION_FAILED"
		if type(self.provider.notify) == "function" then
			pcall(self.provider.notify, code, SAFE_MESSAGES[code])
		end
	end
	error(code, 0)
end

function Loader:Unload()
	if self.state == "unloaded" then
		return
	end
	self.state = "unloading"
	self:_runCleanup()
	self.state = "unloaded"
	status(self.provider, "unloaded", "Loader descargado.")
end

return Loader
end
moduleFactories["public/delta_provider"] = function(__infinity_public_require)
local require = __infinity_public_require
--!nonstrict
-- Operational public capability provider for WI038. Tokens delimited by
-- __WI038_*__ are replaced only by the exact-ref candidate builder.

local ENDPOINT = "https://divisions-ser-untitled-tcp.trycloudflare.com"
local MANIFEST_KID = "kid_manifest_wi038_beta_01"
local MANIFEST_PUBLIC_B64URL = "zKb4VJHBD0RINlGbFTtwiQufXB9-8HLoFsDLA6CQPk0"
local GRANT_KID = "kid_grant_wi038_beta_01"
local GRANT_PUBLIC_B64URL = "ckp3aYBktQlIEpMDvgWlTPTU6sOyp9P76PsAAb0jNlY"
local GRANT_ISSUER = "licensing.infinity.quick-tunnel-beta"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local environment = if type(getgenv) == "function" then getgenv() else _G

local Ed25519 = require("./ed25519_verify")
local AdapterRuntime = require("./adapter_runtime")
local PrivateLoader = require("./private_loader")

local function hexToRaw(value: any, expectedBytes: number?): string?
	if type(value) ~= "string" or #value % 2 ~= 0 or string.match(value, "^[0-9a-fA-F]+$") == nil then return nil end
	local parts = table.create(#value / 2)
	for index = 1, #value, 2 do parts[(index + 1) / 2] = string.char(tonumber(string.sub(value, index, index + 1), 16) :: number) end
	local result = table.concat(parts)
	if expectedBytes ~= nil and #result ~= expectedBytes then return nil end
	return result
end

local BASE64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64Encode(raw: string): string
	local output = {}
	for index = 1, #raw, 3 do
		local a = string.byte(raw, index) or 0
		local b = string.byte(raw, index + 1) or 0
		local c = string.byte(raw, index + 2) or 0
		local value = a * 65536 + b * 256 + c
		table.insert(output, string.sub(BASE64_ALPHABET, math.floor(value / 262144) % 64 + 1, math.floor(value / 262144) % 64 + 1))
		table.insert(output, string.sub(BASE64_ALPHABET, math.floor(value / 4096) % 64 + 1, math.floor(value / 4096) % 64 + 1))
		table.insert(output, index + 1 <= #raw and string.sub(BASE64_ALPHABET, math.floor(value / 64) % 64 + 1, math.floor(value / 64) % 64 + 1) or "=")
		table.insert(output, index + 2 <= #raw and string.sub(BASE64_ALPHABET, value % 64 + 1, value % 64 + 1) or "=")
	end
	return table.concat(output)
end

local function base64Decode(value: any): string?
	if type(value) ~= "string" or #value == 0 or #value % 4 ~= 0 or string.match(value, "^[A-Za-z0-9+/=]+$") == nil then return nil end
	local paddingAt = string.find(value, "=", 1, true)
	if paddingAt ~= nil then
		local padding = string.sub(value, paddingAt)
		if #padding > 2 or string.match(padding, "^=+$") == nil then return nil end
	end
	local lookup = {}
	for index = 1, #BASE64_ALPHABET do lookup[string.sub(BASE64_ALPHABET, index, index)] = index - 1 end
	local output = {}
	for index = 1, #value, 4 do
		local c1, c2 = lookup[string.sub(value, index, index)], lookup[string.sub(value, index + 1, index + 1)]
		local third, fourth = string.sub(value, index + 2, index + 2), string.sub(value, index + 3, index + 3)
		local c3, c4 = if third == "=" then 0 else lookup[third], if fourth == "=" then 0 else lookup[fourth]
		if c1 == nil or c2 == nil or c3 == nil or c4 == nil then return nil end
		local combined = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
		table.insert(output, string.char(math.floor(combined / 65536) % 256))
		if third ~= "=" then table.insert(output, string.char(math.floor(combined / 256) % 256)) end
		if fourth ~= "=" then table.insert(output, string.char(combined % 256)) end
	end
	local result = table.concat(output)
	if base64Encode(result) ~= value then return nil end
	return result
end

local function b64urlEncode(raw: string): string
	return (string.gsub(string.gsub(string.gsub(base64Encode(raw), "+", "-"), "/", "_"), "=+$", ""))
end

local function b64urlDecode(value: any): string?
	if type(value) ~= "string" or #value == 0 or string.find(value, "=", 1, true) or string.match(value, "^[A-Za-z0-9_-]+$") == nil then return nil end
	local standard = string.gsub(string.gsub(value, "-", "+"), "_", "/") .. string.rep("=", (4 - #value % 4) % 4)
	local result = base64Decode(standard)
	if result == nil or b64urlEncode(result) ~= value then return nil end
	return result
end

local function jsonString(value: string): string
	if string.match(value, "^[\0-\127]*$") == nil then error("CANONICAL_JSON_INVALID", 0) end
	return '"' .. string.gsub(value, '[%z\1-\31\\"]', function(character)
		local escapes = { ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
		return escapes[character] or string.format("\\u%04x", string.byte(character))
	end) .. '"'
end

local function canonicalJSON(value: any): string
	local kind = type(value)
	if value == nil then return "null" end
	if kind == "boolean" then return value and "true" or "false" end
	if kind == "string" then return jsonString(value) end
	if kind == "number" then
		if value ~= math.floor(value) or math.abs(value) > 9007199254740991 then error("CANONICAL_JSON_INVALID", 0) end
		return string.format("%.0f", value)
	end
	if kind ~= "table" then error("CANONICAL_JSON_INVALID", 0) end
	local count, maximum, array = 0, 0, true
	for key, _ in pairs(value) do
		count += 1
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then array = false else maximum = math.max(maximum, key) end
	end
	array = array and count > 0 and maximum == count
	local output = {}
	if array then
		for index = 1, count do table.insert(output, canonicalJSON(value[index])) end
		return "[" .. table.concat(output, ",") .. "]"
	end
	local keys = {}
	for key, _ in pairs(value) do if type(key) ~= "string" then error("CANONICAL_JSON_INVALID", 0) end; table.insert(keys, key) end
	table.sort(keys)
	for _, key in ipairs(keys) do table.insert(output, jsonString(key) .. ":" .. canonicalJSON(value[key])) end
	return "{" .. table.concat(output, ",") .. "}"
end

local cryptTable = environment.crypt or environment.crypto
local hashFunction = type(cryptTable) == "table" and cryptTable.hash or nil
local function selectHash(): ((string, string) -> string)?
	if type(hashFunction) ~= "function" then return nil end
	local expected256 = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
	local expected512 = "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
	for _, candidate in ipairs({
		function(data, algorithm) return hashFunction(data, algorithm) end,
		function(data, algorithm) return hashFunction(algorithm, data) end,
	}) do
		local ok256, digest256 = pcall(candidate, "abc", "sha256")
		local ok512, digest512 = pcall(candidate, "abc", "sha512")
		if ok256 and ok512 and type(digest256) == "string" and type(digest512) == "string"
			and string.lower(digest256) == expected256 and string.lower(digest512) == expected512 then return candidate end
	end
	return nil
end
local selectedHash = selectHash()
local function digestHex(data: string, algorithm: string): string
	if selectedHash == nil then error("CAPABILITY_UNAVAILABLE", 0) end
	local result = string.lower(selectedHash(data, algorithm))
	local size = if algorithm == "sha256" then 64 else 128
	if #result ~= size or string.match(result, "^[0-9a-f]+$") == nil then error("CAPABILITY_UNAVAILABLE", 0) end
	return result
end
local function sha512Raw(data: string): string
	return hexToRaw(digestHex(data, "sha512"), 64) :: string
end

do
	local publicKey = hexToRaw("d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a", 32)
	local signature = hexToRaw("e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b", 64)
	if publicKey == nil or signature == nil or not Ed25519.verify("", signature, publicKey, sha512Raw) then
		error("CAPABILITY_UNAVAILABLE", 0)
	end
end

local randomFunction = type(cryptTable) == "table" and cryptTable.generatebytes or nil
local function randomBytes(count: number): string
	if type(randomFunction) ~= "function" then error("CAPABILITY_UNAVAILABLE", 0) end
	local ok, encoded = pcall(randomFunction, count)
	local decoded = ok and base64Decode(encoded) or nil
	if decoded == nil or #decoded ~= count then error("CAPABILITY_UNAVAILABLE", 0) end
	return decoded
end

local requestFunction = environment.request or environment.http_request
if type(requestFunction) ~= "function" and type(environment.syn) == "table" then requestFunction = environment.syn.request end
local function httpsPost(path: string, body: string, headers: any): any
	if type(requestFunction) ~= "function" or string.match(ENDPOINT, "^https://[a-z0-9-]+%.trycloudflare%.com$") == nil then error("CAPABILITY_UNAVAILABLE", 0) end
	headers["Content-Type"] = headers["Content-Type"] or "application/json"
	local ok, response = pcall(requestFunction, { Url = ENDPOINT .. path, Method = "POST", Headers = headers, Body = body })
	if not ok or type(response) ~= "table" then return { status = 0, body = "", kind = "ambiguous_transport" } end
	local status = tonumber(response.StatusCode or response.Status or response.status_code)
	local responseBody = response.Body or response.body
	if status == nil or type(responseBody) ~= "string" or #responseBody > 2 * 1024 * 1024 then return { status = 0, body = "", kind = "ambiguous_transport" } end
	return { status = status, body = responseBody, headers = response.Headers or response.headers or {} }
end

local function uuid(): string
	local value = { string.byte(randomBytes(16), 1, 16) }
	value[7] = bit32.bor(bit32.band(value[7], 0x0f), 0x40)
	value[9] = bit32.bor(bit32.band(value[9], 0x3f), 0x80)
	local encoded = {}
	for index, byte in ipairs(value) do encoded[index] = string.format("%02x", byte) end
	return table.concat(encoded, "", 1, 4) .. "-" .. table.concat(encoded, "", 5, 6) .. "-" .. table.concat(encoded, "", 7, 8) .. "-" .. table.concat(encoded, "", 9, 10) .. "-" .. table.concat(encoded, "", 11, 16)
end

local function parseUtc(value: any): number?
	if type(value) ~= "string" then return nil end
	local year, month, day, hour, minute, second = string.match(value, "^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)Z$")
	if year == nil then return nil end
	local ok, timestamp = pcall(function()
		return DateTime.fromUniversalTime(tonumber(year), tonumber(month), tonumber(day), tonumber(hour), tonumber(minute), tonumber(second)).UnixTimestamp
	end)
	return ok and timestamp or nil
end

local manifestPublic = b64urlDecode(MANIFEST_PUBLIC_B64URL)
local grantPublic = b64urlDecode(GRANT_PUBLIC_B64URL)
if manifestPublic == nil or #manifestPublic ~= 32 or grantPublic == nil or #grantPublic ~= 32 then error("CAPABILITY_UNAVAILABLE", 0) end

local state = { manifest = nil, grant = nil }
local provider = {}

function provider.newIdentity()
	local player = Players.LocalPlayer
	if player == nil then error("LOAD_IDENTITY_INVALID", 0) end
	return {
		load_id = uuid(), instance_nonce = b64urlEncode(randomBytes(24)),
		configured_user_id = tostring(player.UserId), installation_pseudonym = nil,
		idempotency_key = "idem_" .. b64urlEncode(randomBytes(24)),
	}
end

provider.encodeCanonicalJSON = canonicalJSON

local runtimeCapability = {
	probe = function(_capability)
		return if selectedHash ~= nil and type(requestFunction) == "function" and type(loadstring) == "function" then "verified" else "unavailable"
	end,
	notify = function(_code, _message) end,
	sha256 = function(data) return digestHex(data, "sha256") end,
	base64urlDecodeCanonical = function(value)
		local decoded = b64urlDecode(value); if decoded == nil then error("BUNDLE_INVALID", 0) end; return decoded
	end,
	canonicalizeModuleIndex = canonicalJSON,
}

function runtimeCapability.authorize(requestBytes, idempotencyKey)
	return httpsPost("/v3/load-authorizations", requestBytes, { ["X-Infinity-Contract"] = "v3-beta", ["Idempotency-Key"] = idempotencyKey })
end

function runtimeCapability.validateAuthorizationRequest(requestBytes, idempotencyKey)
	local ok, request = pcall(HttpService.JSONDecode, HttpService, requestBytes)
	if not ok or type(request) ~= "table" or request.schema ~= "load-authorization-request/v3-beta"
		or type(request.runtime_context) ~= "table" or request.runtime_context.place_id ~= tostring(game.PlaceId)
		or request.target ~= nil or request.product_id ~= nil or type(idempotencyKey) ~= "string" then error("AUTHORIZATION_FAILED", 0) end
	return request
end

function runtimeCapability.validateAuthorizationResponse(response, request)
	if response.status ~= 201 or type(response.body) ~= "string" then error("AUTHORIZATION_FAILED", 0) end
	local ok, authorization = pcall(HttpService.JSONDecode, HttpService, response.body)
	response.body = ""
	if not ok or type(authorization) ~= "table" or authorization.schema ~= "load-authorization-response/v2-draft"
		or authorization.load_id ~= request.load_id or type(authorization.manifest) ~= "table"
		or type(authorization.grant) ~= "table" or parseUtc(authorization.server_time) == nil then error("AUTHORIZATION_FAILED", 0) end
	return authorization
end

function runtimeCapability.verifyManifest(manifest, request)
	if type(manifest) ~= "table" or manifest.schema ~= 2 or manifest.contract_version ~= "private-payload-delivery/v1-draft"
		or manifest.product_id == nil or type(manifest.artifact) ~= "table" or type(manifest.source) ~= "table"
		or type(manifest.signing) ~= "table" or manifest.signing.manifest_signing_kid ~= MANIFEST_KID
		or manifest.signing.algorithm ~= "EdDSA" or manifest.signing.canonicalization ~= "RFC8785-JCS"
		or type(manifest.signature_base64url) ~= "string" then error("MANIFEST_INVALID", 0) end
	local signature = b64urlDecode(manifest.signature_base64url)
	local unsigned = {}; for key, value in pairs(manifest) do if key ~= "signature_base64url" then unsigned[key] = value end end
	local canonical = canonicalJSON(unsigned)
	if signature == nil or not Ed25519.verify("InfinityPlatform\0manifest\0v2\0" .. canonical, signature, manifestPublic, sha512Raw) then error("MANIFEST_INVALID", 0) end
	local artifact = manifest.artifact
	if artifact.artifact_id ~= "sha256:" .. tostring(artifact.sha256) or type(artifact.size_bytes) ~= "number"
		or artifact.size_bytes < 1 or artifact.size_bytes > 16777216 or type(artifact.build_id) ~= "string"
		or type(artifact.component_version) ~= "string" then error("MANIFEST_INVALID", 0) end
	local inputs = manifest.source.inputs
	if type(inputs) ~= "table" or #inputs < 1 or #inputs > 32 then error("MANIFEST_INVALID", 0) end
	if parseUtc(manifest.created_at) == nil or parseUtc(manifest.expires_at) == nil or (parseUtc(manifest.expires_at) :: number) < DateTime.now().UnixTimestamp - 15 then error("MANIFEST_INVALID", 0) end
	state.manifest = manifest
	return manifest
end

function runtimeCapability.verifyGrantAndExactScope(grant, manifest, request, authorization)
	if type(grant) ~= "table" or grant.schema ~= "private-payload-grant-envelope/v1" or grant.algorithm ~= "EdDSA"
		or grant.grant_signing_kid ~= GRANT_KID or type(grant.claims) ~= "table" then error("GRANT_INVALID", 0) end
	local claims = grant.claims
	local signature = b64urlDecode(grant.signature_base64url)
	if signature == nil or claims.grant_signing_kid ~= GRANT_KID
		or not Ed25519.verify("InfinityPlatform\0grant\0v1\0" .. canonicalJSON(claims), signature, grantPublic, sha512Raw) then error("GRANT_INVALID", 0) end
	local unsigned = {}; for key, value in pairs(manifest) do if key ~= "signature_base64url" then unsigned[key] = value end end
	local manifestDigest = digestHex(canonicalJSON(unsigned), "sha256")
	local artifact = manifest.artifact
	if claims.operation ~= "artifact.redeem" or claims.issuer ~= GRANT_ISSUER or claims.audience ~= "infinity-private-delivery"
		or claims.load_id ~= request.load_id or claims.authorization_id ~= authorization.authorization_id
		or claims.product_id ~= manifest.product_id or claims.release_id ~= manifest.release_id
		or claims.build_id ~= artifact.build_id or claims.artifact_id ~= artifact.artifact_id
		or claims.manifest_sha256 ~= manifestDigest then error("GRANT_INVALID", 0) end
	local issued, notBefore, expires = parseUtc(claims.issued_at), parseUtc(claims.not_before), parseUtc(claims.expires_at)
	local now = DateTime.now().UnixTimestamp
	if issued == nil or notBefore == nil or expires == nil or expires - issued ~= 120 or now < notBefore - 15 or now > expires + 15 then error("GRANT_INVALID", 0) end
	state.grant = grant
	return grant
end

function runtimeCapability.redeemExactlyOnce(grant, _authorizationRequestId)
	local claims = grant.claims
	local requestId = uuid()
	local body = canonicalJSON({ artifact_id = claims.artifact_id, manifest_sha256 = claims.manifest_sha256 })
	return httpsPost("/v1/deliveries/redeem", body, {
		Authorization = "PrivateGrant " .. b64urlEncode(canonicalJSON(grant)),
		["X-Infinity-Contract"] = "v1-draft", ["X-Request-Id"] = requestId,
		Accept = "application/octet-stream",
	})
end

function runtimeCapability.decodeCanonicalJSON(bundleBytes)
	local ok, bundle = pcall(HttpService.JSONDecode, HttpService, bundleBytes)
	if not ok or type(bundle) ~= "table" then error("BUNDLE_INVALID", 0) end
	return bundle
end

function runtimeCapability.validateBundleEnvelope(bundle, artifact)
	if bundle.schema ~= "private-runtime-bundle/v1" or bundle.entrypoint_module ~= artifact.entrypoint_module or type(bundle.modules) ~= "table" then return false end
	for _, item in ipairs(bundle.modules) do
		if type(item) ~= "table" or type(item.module_id) ~= "string" or type(item.dependencies) ~= "table"
			or type(item.source_sha256) ~= "string" or type(item.source_size_bytes) ~= "number" or type(item.source_base64url) ~= "string" then return false end
	end
	return true
end

local adapterRuntime = nil

local function platformContext(adapterSource)
	local cleanups, cancelled = {}, false
	local lifecycle = {}
	function lifecycle:trackCleanup(name, callback)
		if type(name) ~= "string" or type(callback) ~= "function" or cleanups[name] ~= nil then return false end
		cleanups[name] = callback; return true
	end
	function lifecycle:isCancelled() return cancelled end
	local function handle()
		local value = { phase = "scheduled", worker = nil }
		function value:cancel(_reason) if self.phase == "running" then self.phase = "cancelled"; pcall(task.cancel, self.worker) end end
		function value:state() return self.phase end
		return value
	end
	local scheduler = {}
	function scheduler:spawn(_name, callback)
		local result = handle()
		result.worker = task.spawn(function() result.phase = "running"; local ok = pcall(callback); result.phase = ok and "completed" or "failed" end)
		return result
	end
	function scheduler:delay(_name, seconds, callback)
		local result = handle()
		result.worker = task.delay(seconds, function() result.phase = "running"; local ok = pcall(callback); result.phase = ok and "completed" or "failed" end)
		return result
	end
	local capabilities = {}
	function capabilities:has(capability) return capability == "config.v1" or capability == "scheduler.v1" or capability == "ui.v1" end
	return {
		contractVersion = "v1-draft", coreVersion = "0.1.0",
		product = { productId = state.manifest.product_id, adapterVersion = adapterSource.component_version, buildId = adapterSource.component_build_id },
		environment = { universeId = tostring(game.GameId), placeId = tostring(game.PlaceId) },
		capabilities = capabilities, lifecycle = lifecycle, scheduler = scheduler,
		notify = function(_code, _message) end,
	}
end

local runtimeManifest, runtimeAdapterSource = nil, nil
local function getAdapterRuntime(manifest, adapterSource)
	if manifest ~= state.manifest or type(adapterSource) ~= "table" then error("ADAPTER_MANIFEST_MISMATCH", 0) end
	if adapterRuntime == nil then
		adapterRuntime = AdapterRuntime.new({
			loadstring = loadstring,
			distributionManifest = manifest,
			adapterSource = adapterSource,
			expected = { productId = state.manifest.product_id, coreVersion = "0.1.0", universeId = tostring(game.GameId), placeId = tostring(game.PlaceId) },
			platformContext = platformContext(adapterSource),
		})
		runtimeManifest, runtimeAdapterSource = manifest, adapterSource
	elseif manifest ~= runtimeManifest or adapterSource ~= runtimeAdapterSource then
		error("ADAPTER_MANIFEST_MISMATCH", 0)
	end
	return adapterRuntime
end

runtimeCapability.compile = function(moduleId, source, manifest, adapterSource)
	return getAdapterRuntime(manifest, adapterSource):Compile(moduleId, source)
end

function runtimeCapability.start(entrypoint, compiled, manifest, _request, _authorization, adapterSource)
	return getAdapterRuntime(manifest, adapterSource):Start(entrypoint, compiled)
end

function provider.executeOnce(requestBytes, idempotencyKey)
	local previous = environment.__INFINITY_WI038_CLEANUP
	if type(previous) == "function" then pcall(previous); environment.__INFINITY_WI038_CLEANUP = nil end
	local loader = PrivateLoader.new({
		operational = true, authorization_transport_retry = 0,
		required_capabilities = { "crypto.sha256.v1", "crypto.signature.verify.v1", "runtime.luau.loadstring", "time.utc.rfc3339.v1", "transport.https-post-headers-json.v1", "transport.response-bounded-bytes.v1" },
	}, runtimeCapability)
	loader:Load(requestBytes, idempotencyKey)
	environment.__INFINITY_WI038_CLEANUP = function() loader:Unload() end
	return { ok = true }
end

return provider
end
local moduleCache = {
    ["public/MultiPrecision"] = MultiPrecision,
    ["public/FieldQuadratic"] = FieldQuadratic,
    ["public/FieldPrime"] = FieldPrime,
    ["public/Edwards25519"] = Edwards25519,
    ["public/ed25519_verify"] = Ed25519,
}
local moduleLoading = {}
local loadPublicModule
local function resolvePublicModule(parentId, requested)
    if type(requested) ~= "string" then error("PUBLIC_MODULE_REQUIRE_INVALID", 0) end
    if string.sub(requested, 1, 2) == "./" then
        local prefix = string.match(parentId, "^(.*)/[^/]+$")
        if prefix == nil or string.find(string.sub(requested, 3), "/", 1, true) ~= nil then
            error("PUBLIC_MODULE_REQUIRE_INVALID", 0)
        end
        return prefix .. "/" .. string.sub(requested, 3)
    end
    return requested
end
loadPublicModule = function(moduleId)
    if moduleCache[moduleId] ~= nil then return moduleCache[moduleId] end
    if moduleLoading[moduleId] then error("PUBLIC_MODULE_CYCLE", 0) end
    local factory = moduleFactories[moduleId]
    if type(factory) ~= "function" then error("PUBLIC_MODULE_MISSING", 0) end
    moduleLoading[moduleId] = true
    local ok, exported = pcall(factory, function(requested)
        return loadPublicModule(resolvePublicModule(moduleId, requested))
    end)
    moduleLoading[moduleId] = nil
    if not ok or exported == nil then error("PUBLIC_MODULE_LOAD_FAILED", 0) end
    moduleCache[moduleId] = exported
    return exported
end
local publicConfig = {
    profile = {
        ["authorization_transport_retry"] = 0,
        ["operational"] = true,
        ["required_capabilities"] = {
            "crypto.sha256.v1",
            "crypto.signature.verify.v1",
            "runtime.luau.loadstring",
            "time.utc.rfc3339.v1",
            "transport.https-post-headers-json.v1",
            "transport.response-bounded-bytes.v1"
        }
    },
    provider = loadPublicModule("public/delta_provider"),
}
local Bootstrap = loadPublicModule("public/universal_roblox_bootstrap")
return Bootstrap.start(publicConfig)
