package com.hilgo.cargo.entity.enums;


public enum CargoSituation {
    CREATED,         // İlan oluşturuldu ama henüz bir sürücü almadı
    ASSIGNED,        // Sürücü bu kargoyu üzerine aldı
    PICKED_UP,       // Kargo teslim alındı (sürücü yolda)
    DELIVERED,       // Kargo başarıyla teslim edildi
    CANCELLED,       // Kargo iptal edildi (distributor veya sistem)
    EXPIRED,         // Kargo belirli sürede alınmadı, sistem pasif hale getirdi
    FAILED           // Teslimat başarısız oldu (adres bulunamadı vs.)
}