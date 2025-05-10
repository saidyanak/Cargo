package com.hilgo.cargo.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.hilgo.cargo.entity.Cargo;
import com.hilgo.cargo.entity.Distributor;
import com.hilgo.cargo.entity.User;
import com.hilgo.cargo.entity.enums.CargoSituation;
import com.hilgo.cargo.repository.CargoRepository;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.request.CargoRequest;
import com.hilgo.cargo.request.DistributorRequest;
import com.hilgo.cargo.response.CargoResponse;
import com.hilgo.cargo.response.DistributorResponse;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DistributorService {
	
	final private UserRepository userRepository;
	final private CargoRepository cargoRepository;
	
	public DistributorResponse updateDistributor(DistributorRequest distributorRequest) {
		
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		User user = userRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("User not found"));
		
		if (!user.getUsername().equals(distributorRequest.getUsername()) && userRepository.existsByUsername(distributorRequest.getUsername())) {
			throw new RuntimeException("Username is already exist.");
		}
		
		if (!user.getMail().equals(distributorRequest.getMail()) && userRepository.existsByMail(distributorRequest.getMail())) {
			throw new RuntimeException("Mail is already exist.");
		}
		
		if (!user.getPhoneNumber().equals(distributorRequest.getPhoneNumber()) && userRepository.existsByPhoneNumber(distributorRequest.getPhoneNumber())) {
			throw new RuntimeException("Phone number is already exist.");
		}
		
		((Distributor)user).setPhoneNumber(distributorRequest.getPhoneNumber());
		((Distributor)user).setAddress(distributorRequest.getAddress());
		user.setUsername(distributorRequest.getUsername());
		user.setMail(distributorRequest.getMail());
		
		userRepository.save(user);
		
		return DistributorResponse.builder()
				.vkn(((Distributor)user).getVkn())
				.username(user.getUsername())
				.address(((Distributor)user).getAddress())
				.password(user.getPassword())
				.phoneNumber(user.getPhoneNumber())
				.mail(user.getMail())
				.build();
		
	}

	public List<CargoResponse> addCargo(CargoRequest cargoRequest) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		User user = userRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("User not found!"));
		
		Cargo cargo = new Cargo();
		cargo.setDistributor(((Distributor)user));
		cargo.setMeasure(cargoRequest.getMeasure());
		cargo.setDescription(cargoRequest.getDescription());
		cargo.setPhoneNumber(cargoRequest.getPhoneNumber());
		cargo.setSelfLocation(cargoRequest.getSelfLocation());
		cargo.setCargoSituation(CargoSituation.CREATED);
		
		cargoRepository.save(cargo);
		
		List<Cargo> cargoList = cargoRepository.findAllByDistributorId(user.getId());

		return cargoList.stream().map(c -> new CargoResponse(
				c.getDescription(),
				c.getSelfLocation(),
				c.getTargetLocation(),
				c.getMeasure(),
				c.getPhoneNumber(),
				c.getCargoSituation()
				)).collect(Collectors.toList());
	}

	public Boolean deleteCargo(Long cargoId) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		User user = userRepository.findByUsername(username)
				.orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı."));
		Cargo cargo = cargoRepository.findByIdAndDistributorId(cargoId, user.getId())
				.orElseThrow(() -> new RuntimeException("Kargo bulunamadı."));
		cargoRepository.delete(cargo);
		
		return true;
	}

	public CargoResponse updateCargo(Long cargoId, CargoRequest cargoRequest) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		userRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("User not found!"));
		
		Cargo cargo = cargoRepository.findById(cargoId).orElseThrow(() -> new RuntimeException("Cargo not found!"));
		
		if (!cargo.getCargoSituation().toString().equals("CREATED")) {
			throw new RuntimeException("Update Error!");
		}
		cargo.setMeasure(cargoRequest.getMeasure());
		cargo.setPhoneNumber(cargoRequest.getPhoneNumber());
		cargo.setSelfLocation(cargoRequest.getSelfLocation());
		cargo.setTargetLocation(cargoRequest.getTargetLocation());
		cargo.setDescription(cargoRequest.getDescription());
		
		cargoRepository.save(cargo);
		
		return CargoResponse.builder()
				.description(cargo.getDescription())
				.selfLocation(cargo.getSelfLocation())
				.targetLocation(cargo.getTargetLocation())
				.measure(cargo.getMeasure())
				.phoneNumber(cargo.getPhoneNumber())
				.cargoSituation(cargo.getCargoSituation())
				.build();
		
	}


}
