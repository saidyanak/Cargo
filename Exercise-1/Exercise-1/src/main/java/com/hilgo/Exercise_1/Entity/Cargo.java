package com.hilgo.Exercise_1.Entity;


import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
public class Cargo {
	
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private long cargoId;
	
	@Column
	private String selfLocation;
	
	@Column
	private String targetLocation;

	@Column
	private Double weight;

	@Column
	private Sizes sizes;
	
	@Column
	private CargoSituation cargoSituation;
	
	@Column
	private String phoneNumber;
	
	@Column
	private Integer verificationCode;
	
	@Column
	private String description;
	
	@Column
	private String deliveryCode;
	
	@Column
	private LocalDateTime takingTime;
	
	@Column
	private LocalDateTime deliveredTime;
	
	@ManyToOne
	@JoinColumn(name = "distributor_id")
	private Distributor distributor;
	

	@ManyToOne
	private Driver driver;
	
	@Enumerated(EnumType.STRING)
	private CargoStatus cargoStatus;
	
	@OneToOne(mappedBy = "cargo")
	private ShipmentsSent shipmentsSent;
	
	
	
}
