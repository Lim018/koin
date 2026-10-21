package com.lim018.koin

/** An outgoing payment read from a bank/e-wallet notification. */
data class DetectedTransaction(
    val amount: Long,
    val category: String,
    val wallet: String,
)

/**
 * Regex/keyword parsing of payment notifications (PRD 4.3). Pure Kotlin so it
 * is unit-tested in src/test.
 */
object TransactionParser {

    /** Notification source groups; ids match the toggles in the settings page. */
    enum class Source(val prefKey: String) {
        GOPAY("koin_src_gopay"),
        BANK("koin_src_bank"),
        EWALLET("koin_src_ewallet"),
    }

    private data class App(val source: Source, val wallet: String)

    private val apps = mapOf(
        "com.gojek.app" to App(Source.GOPAY, "GoPay"),
        "com.gojek.gopay" to App(Source.GOPAY, "GoPay"),
        "com.bca" to App(Source.BANK, "M-Banking"),
        "com.bca.mybca.omni.android" to App(Source.BANK, "M-Banking"),
        "id.bmri.livin" to App(Source.BANK, "M-Banking"),
        "id.co.bri.brimo" to App(Source.BANK, "M-Banking"),
        "src.com.bni" to App(Source.BANK, "M-Banking"),
        "ovo.id" to App(Source.EWALLET, "OVO"),
        "id.dana" to App(Source.EWALLET, "DANA"),
        "com.shopee.id" to App(Source.EWALLET, "ShopeePay"),
    )

    fun sourceOf(packageName: String): Source? = apps[packageName]?.source

    // "Rp25.000", "Rp 25.000,00", "IDR 25,000.00"
    private val amountRegex =
        Regex("""(?:Rp\.?|IDR)\s?([0-9][0-9.,]*[0-9]|[0-9])""", RegexOption.IGNORE_CASE)

    private val outgoing = Regex(
        """bayar|pembayaran|pembelian|berhasil (?:dibayar|membayar)|transfer ke|""" +
            """kirim(?:\s+uang)?\s+ke|debit|tarik tunai|payment|paid""",
        RegexOption.IGNORE_CASE,
    )
    private val incoming = Regex(
        """diterima|menerima|uang masuk|dana masuk|top ?up|isi saldo|cashback|""" +
            """refund|pengembalian|kredit|received""",
        RegexOption.IGNORE_CASE,
    )

    /** Upper bound guarding against parsing account numbers as amounts. */
    private const val MAX_AMOUNT = 100_000_000L

    private val categoryKeywords = listOf(
        "Transport" to Regex("""gojek|goride|gocar|grab(?:bike|car)?|maxim|parkir|tol\b|krl|mrt|transjakarta|bensin|pertamina|shell""", RegexOption.IGNORE_CASE),
        "Makan" to Regex("""gofood|grabfood|shopeefood|resto|makan|warung|bakso|nasi|ayam|pizza|mcd|kfc""", RegexOption.IGNORE_CASE),
        "Jajan" to Regex("""kopi|coffee|starbucks|janji jiwa|kenangan|boba|chatime|indomaret|alfamart""", RegexOption.IGNORE_CASE),
        "Tagihan" to Regex("""pln|listrik|token|pulsa|paket data|pdam|bpjs|tagihan|internet|indihome""", RegexOption.IGNORE_CASE),
        "Belanja" to Regex("""tokopedia|shopee|lazada|blibli|tiktok shop|belanja|mart\b""", RegexOption.IGNORE_CASE),
    )

    /** Null unless [text] from [packageName] describes an outgoing payment. */
    fun parse(packageName: String, text: String): DetectedTransaction? {
        val app = apps[packageName] ?: return null
        if (incoming.containsMatchIn(text) || !outgoing.containsMatchIn(text)) return null
        val amount = amountRegex.find(text)?.groupValues?.get(1)?.let(::parseAmount)
            ?: return null
        if (amount <= 0 || amount > MAX_AMOUNT) return null
        return DetectedTransaction(amount, guessCategory(text), app.wallet)
    }

    /** "25.000" / "25.000,00" / "25,000.00" → 25000 (cents dropped). */
    fun parseAmount(raw: String): Long? {
        val lastSep = raw.indexOfLast { it == '.' || it == ',' }
        val integerPart =
            if (lastSep >= 0 && raw.length - lastSep - 1 == 2) raw.substring(0, lastSep) else raw
        return integerPart.filter(Char::isDigit).toLongOrNull()
    }

    fun guessCategory(text: String): String =
        categoryKeywords.firstOrNull { (_, re) -> re.containsMatchIn(text) }?.first ?: "Lainnya"
}
