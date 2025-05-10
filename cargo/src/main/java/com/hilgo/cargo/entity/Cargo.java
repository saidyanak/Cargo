package com.hilgo.cargo.entity;

import java.time.LocalDateTime;

import com.hilgo.cargo.entity.enums.CargoSituation;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class Cargo {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@OneToOne
	private Location selfLocation;

	@OneToOne
	private Location targetLocation;

	@OneToOne
	private Measure measure;

	@Enumerated(EnumType.STRING)
	private CargoSituation cargoSituation;

	@Column
	private String phoneNumber;

	@Column
	private String verificationCode;
	
	@Column
	private  LocalDateTime takingTime;

	@Column
	private  LocalDateTime deliveredTime;
	
	@Column
	private  String description;
	
	@ManyToOne
	private Distributor distributor;
	
	@ManyToOne
	private Driver driver;
	//@Lob
//    private byte[] qrCodeImage;

}
