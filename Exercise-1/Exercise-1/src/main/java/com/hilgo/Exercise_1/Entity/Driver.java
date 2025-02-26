package com.hilgo.Exercise_1.Entity;

import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
@AllArgsConstructor
public class Driver extends User{
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	@Column
	private Long Tc;
	
	@Column
	private String location;
	
	@Column
	private CarTypes carTypes;
	
	@OneToMany(mappedBy = "driver")
	private List<Cargo> cargo;
	
	@OneToOne(mappedBy = "driver")
	private ShipmentsSent shipmentsSent;
}
