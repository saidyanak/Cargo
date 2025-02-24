package com.hilgo.Exercise_1.service;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.hilgo.Exercise_1.Entity.Cargo;
import com.hilgo.Exercise_1.Entity.Distributor;
import com.hilgo.Exercise_1.repo.CargoRepository;
import com.hilgo.Exercise_1.repo.DistributorRepository;
import com.hilgo.Exercise_1.responses.CargoesResponse;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DistributorService {
	
	final private DistributorRepository distributorRepository;
	final private CargoRepository cargoesRepo;
	
	public Page<CargoesResponse> getMyCargoes(Pageable pageable) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<Distributor> distOptional = distributorRepository.findByUsername(username);
		if(distOptional.isEmpty()) {
			throw new RuntimeException("User not found.");
		}
		Distributor distributor = distOptional.get();
		
		Page<Cargo> cargoesPage = cargoesRepo.findByDistributorId(distributor.getId(), pageable);
		Page<CargoesResponse> cargoResponse = cargoesPage.map(cargo -> new CargoesResponse(cargo.getCargoId(),cargo.getDescription(),cargo.getCargoSituation(), cargo.getPhoneNumber()));
		return cargoResponse;
	}
	
	
}
