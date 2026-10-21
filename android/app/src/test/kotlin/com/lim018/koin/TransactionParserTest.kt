package com.lim018.koin

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class TransactionParserTest {
    @Test
    fun gopayFoodPayment() {
        val t = TransactionParser.parse(
            "com.gojek.app",
            "Pembayaran berhasil · Kamu bayar Rp25.000 ke GoFood Nasi Padang Sederhana",
        )
        assertEquals(DetectedTransaction(25_000, "Makan", "GoPay"), t)
    }

    @Test
    fun bankTransferWithCents() {
        val t = TransactionParser.parse("com.bca", "Transfer ke ANDI sebesar IDR 150,000.00 berhasil")
        assertEquals(150_000L, t?.amount)
        assertEquals("M-Banking", t?.wallet)
        assertEquals("Lainnya", t?.category)
    }

    @Test
    fun indonesianDecimalComma() {
        assertEquals(35_000L, TransactionParser.parseAmount("35.000,00"))
        assertEquals(35_000L, TransactionParser.parseAmount("35.000"))
        assertEquals(1_250_000L, TransactionParser.parseAmount("1.250.000"))
        assertEquals(500L, TransactionParser.parseAmount("500"))
    }

    @Test
    fun ignoresIncomingMoney() {
        assertNull(TransactionParser.parse("ovo.id", "Top Up Rp100.000 berhasil"))
        assertNull(TransactionParser.parse("id.dana", "Kamu menerima Rp50.000 dari Budi"))
        assertNull(TransactionParser.parse("com.gojek.app", "Cashback Rp5.000 masuk, bayar lagi yuk"))
    }

    @Test
    fun ignoresPromosAndUnknownApps() {
        assertNull(TransactionParser.parse("com.gojek.app", "Diskon 50% untuk GoFood hari ini!"))
        assertNull(TransactionParser.parse("com.whatsapp", "Bayar Rp25.000 ya"))
    }

    @Test
    fun rejectsImplausibleAmounts() {
        assertNull(TransactionParser.parse("com.bca", "Pembayaran Rp 0 berhasil"))
        assertNull(TransactionParser.parse("com.bca", "Pembayaran Rp 9.999.999.999 berhasil"))
    }

    @Test
    fun guessesCategories() {
        assertEquals("Transport", TransactionParser.guessCategory("GoRide ke kantor"))
        assertEquals("Tagihan", TransactionParser.guessCategory("Token PLN 20 kWh"))
        assertEquals("Jajan", TransactionParser.guessCategory("Kopi Kenangan"))
    }
}
