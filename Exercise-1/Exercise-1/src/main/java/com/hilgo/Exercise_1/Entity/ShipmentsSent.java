package com.hilgo.Exercise_1.Entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
public class ShipmentsSent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "distributor_id")
    private Distributor distributor;

    @OneToOne
    @JoinColumn(name = "driver_id")
    private Driver driver;

    @OneToOne
    @JoinColumn(name = "cargo_id")
    private Cargo cargo;

    @Column
    private LocalDateTime date;

	
}
