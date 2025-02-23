package com.hilgo.Exercise_1.Entity;

import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;

@Entity
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
	
	@ManyToOne
	@JoinColumn(name = "distributor_id")
	private Distributor distributor;
	
	@OneToMany(mappedBy = "cargo")
	private List<Driver> driver;
	
	
	
}
