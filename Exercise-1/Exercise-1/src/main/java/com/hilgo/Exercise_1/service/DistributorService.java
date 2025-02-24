package com.hilgo.Exercise_1.service;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.hilgo.Exercise_1.Entity.Cargo;
import com.hilgo.Exercise_1.Entity.Distributor;
import com.hilgo.Exercise_1.Entity.User;
import com.hilgo.Exercise_1.repo.CargoRepository;
import com.hilgo.Exercise_1.repo.DistributorRepository;
import com.hilgo.Exercise_1.repo.UserRepository;
import com.hilgo.Exercise_1.request.DistributorRequest;
import com.hilgo.Exercise_1.responses.CargoesResponse;
import com.hilgo.Exercise_1.responses.DistributorResponse;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DistributorService {
	
	final private DistributorRepository distributorRepository;
	final private CargoRepository cargoesRepo;
	final private UserRepository userRepository;
	
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

	public DistributorResponse updateDist(DistributorRequest distributorRequest) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> distOpt = userRepository.findByUsername(username);
		if (!distOpt.get().getUsername().equals(distributorRequest.getUsername()) && userRepository.existsByUsername(distributorRequest.getUsername())) {
			throw new RuntimeException("Username is already exist.");
		}
		
		if (!distOpt.get().getMail().equals(distributorRequest.getMail()) && userRepository.existsByEmail(distributorRequest.getMail())) {
			throw new RuntimeException("Mail is already exist.");
		}
		
		if (distOpt.isEmpty()) {
			throw new RuntimeException("User is not found.");
		}
		User dist = distOpt.get();
		((Distributor)dist).setAddress(distributorRequest.getAddress());
		((Distributor)dist).setPhoneNumber(distributorRequest.getPhoneNumber());
		dist.setMail(distributorRequest.getMail());
		dist.setUsername(distributorRequest.getUsername());
		dist.setId(distOpt.get().getId());
		
		userRepository.save(dist);
		
		
		return DistributorResponse.builder()
				.username(dist.getUsername())
				.address(((Distributor)dist).getAddress())
				.phoneNumber(((Distributor)dist).getPhoneNumber())
				.mail(dist.getMail())
				.build()
				;
	}

	public Boolean deleteDist() {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> optUser = userRepository.findByUsername(username);
		if (optUser.isEmpty()) {
			throw new RuntimeException("User is not exist.");
		}
		User user = optUser.get();
		userRepository.delete(user);
		
		return true;
	}

	
	
}
