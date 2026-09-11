package com.shopzo.app.core.model

/**
 * Units of measurement for products.
 */
enum class ProductUnit(val displayName: String) {
    PIECE("Piece"),
    KG("Kg"),
    GRAM("Gram"),
    LITRE("Litre"),
    ML("Ml"),
    BOX("Box"),
    PACKET("Packet"),
    DOZEN("Dozen")
}
