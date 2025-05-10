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
<<<<<<< HEAD
	private Location selfLocation;

	@OneToOne
	private Location targetLocation;
=======
	private Location selflocation;

	@OneToOne
	private Location targetlocation;
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2

	@OneToOne
	private Measure measure;

	@Enumerated(EnumType.STRING)
	private CargoSituation cargoSituation;

	@Column
	private String phoneNumber;

	@Column
	private String verificationCode;
	
	@Column
<<<<<<< HEAD
	private  LocalDateTime takingTime;
=======
	private  LocalDateTime takeingTime;
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2

	@Column
	private  LocalDateTime deliveredTime;
	
<<<<<<< HEAD
	@Column
	private  String description;
	
=======
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
	@ManyToOne
	private Distributor distributor;
	
	@ManyToOne
	private Driver driver;
	//@Lob
//    private byte[] qrCodeImage;

}
