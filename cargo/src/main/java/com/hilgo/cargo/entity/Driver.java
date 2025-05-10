package com.hilgo.cargo.entity;

import java.util.List;

import com.hilgo.cargo.entity.enums.CarType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Driver extends User{
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	@Column
	private String tc;
	
	@OneToOne
	private Location location;
	
	@OneToMany(mappedBy = "driver")
	private List<Cargo> cargo;
	
	@Enumerated(EnumType.STRING)
	private CarType carType;
}
