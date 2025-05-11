package com.hilgo.cargo.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.hilgo.cargo.entity.Address;
import com.hilgo.cargo.entity.Cargo;
import com.hilgo.cargo.entity.Distributor;
import com.hilgo.cargo.entity.Location;
import com.hilgo.cargo.entity.Measure;
import com.hilgo.cargo.entity.User;
import com.hilgo.cargo.entity.enums.CargoSituation;
import com.hilgo.cargo.repository.AddressRepository;
import com.hilgo.cargo.repository.CargoRepository;
import com.hilgo.cargo.repository.DistributorRepository;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.request.CargoRequest;
import com.hilgo.cargo.request.DistributorRequest;
import com.hilgo.cargo.response.CargoResponse;
import com.hilgo.cargo.response.CargoesResponse;
import com.hilgo.cargo.response.DistributorResponse;
import com.hilgo.cargo.response.ResponseLocation;
import com.hilgo.cargo.response.ResponseMeasure;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DistributorService {
	
	final private UserRepository userRepository;
	final private CargoRepository cargoRepository;
	final private DistributorRepository distributorRepository;
	final private AddressRepository addressRepository;
	
	public DistributorResponse updateDistributor(DistributorRequest distributorRequest) {
		
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		User user = userRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("User not found"));
		
		if (!user.getUsername().equals(distributorRequest.getUsername()) && userRepository.existsByUsername(distributorRequest.getUsername())) {
			throw new RuntimeException("Username is already exist." + user.getUsername() + ":" + distributorRequest.getUsername());
		}
		
		if (!user.getMail().equals(distributorRequest.getMail()) && userRepository.existsByMail(distributorRequest.getMail())) {
			throw new RuntimeException("Mail is already exist.");
		}
		
		if (!user.getPhoneNumber().equals(distributorRequest.getPhoneNumber()) && userRepository.existsByPhoneNumber(distributorRequest.getPhoneNumber())) {
			throw new RuntimeException("Phone number is already exist.");
		}
		
		Optional<Distributor> optDist = distributorRepository.findById(user.getId());
		if(optDist.isEmpty())
			throw new RuntimeException("User Not Found!!");
		Distributor dist = optDist.get();
		Address address = new Address(null, 
		distributorRequest.getAddress().getCity(),
		distributorRequest.getAddress().getNeighbourhood(),
		distributorRequest.getAddress().getStreet(),
		distributorRequest.getAddress().getBuild());
		dist.setAddress(address);
		dist.setPhoneNumber(distributorRequest.getPhoneNumber());
		dist.setUsername(distributorRequest.getUsername());
		dist.setMail(distributorRequest.getMail());
		/*((Distributor)user).setPhoneNumber(distributorRequest.getPhoneNumber());
		((Distributor)user).setAddress(
			new Address(null, distributorRequest.getAddress().getCity(),
		distributorRequest.getAddress().getNeighbourhood(),
		distributorRequest.getAddress().getStreet(),
		distributorRequest.getAddress().getBuild()));
		user.setUsername(distributorRequest.getUsername());
		user.setMail(distributorRequest.getMail());
		userRepository.save(user);
		*/
		addressRepository.save(address);
		distributorRepository.save(dist);
		return DistributorResponse.builder()
				.vkn(((Distributor)user).getVkn())
				.username(user.getUsername())
				.address(distributorRequest.getAddress())
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
		cargo.setMeasure(new Measure(null, cargoRequest.getMeasure().getWeight(), cargoRequest.getMeasure().getHeight(), cargoRequest.getMeasure().getSize()));
		cargo.setDescription(cargoRequest.getDescription());
		cargo.setPhoneNumber(cargoRequest.getPhoneNumber());
		cargo.setSelfLocation(new Location(null, cargoRequest.getSelfLocation().getLatitude(),  cargoRequest.getSelfLocation().getLongitude(), LocalDateTime.now()));
		cargo.setTargetLocation(new Location(null, cargoRequest.getTargetLocation().getLatitude(),  cargoRequest.getTargetLocation().getLongitude(), LocalDateTime.now()));

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
		cargo.setMeasure(new Measure(null, cargoRequest.getMeasure().getWeight(), cargoRequest.getMeasure().getHeight(), cargoRequest.getMeasure().getSize()));
		cargo.setDescription(cargoRequest.getDescription());
		cargo.setPhoneNumber(cargoRequest.getPhoneNumber());
		cargo.setSelfLocation(new Location(null, cargoRequest.getSelfLocation().getLatitude(),  cargoRequest.getSelfLocation().getLongitude(), LocalDateTime.now()));
		cargo.setTargetLocation(new Location(null, cargoRequest.getTargetLocation().getLatitude(),  cargoRequest.getTargetLocation().getLongitude(), LocalDateTime.now()));
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

    public Page<CargoesResponse> getMyCargoes(Pageable pageable) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> userOpt = userRepository.findByUsername(username);

		if (userOpt.isEmpty()) {
			throw new RuntimeException("User not found.");
		}
		Distributor distributor = (Distributor) userRepository.findByUsername(username).get();

		Page<Cargo> cargoesPage = cargoRepository.findByDistributorId(distributor.getId(), pageable);
		Page<CargoesResponse> cargoResponse = cargoesPage.map(cargo -> new CargoesResponse(
				cargo.getId(),
				new ResponseLocation(cargo.getSelfLocation().getLatitude(), cargo.getSelfLocation().getLongitude()),
				new ResponseLocation(cargo.getTargetLocation().getLatitude(), cargo.getTargetLocation().getLongitude()),
				new ResponseMeasure(cargo.getMeasure().getWeight(), cargo.getMeasure().getHeight(), cargo.getMeasure().getSize()),
				cargo.getCargoSituation(),
				cargo.getPhoneNumber(), 
				cargo.getDistributor().getPhoneNumber()));
		return cargoResponse;
    }
}
